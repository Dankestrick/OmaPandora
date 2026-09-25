import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "Api.js" as Api

Item {
  id: root

  property var shell: null
  property var manifest: null
  property var settings: ({})

  property var status: ({})
  property string lastError: ""
  property bool uiVisible: false
  property var playerSurfaces: []
  property bool autoplayArmed: false
  property bool daemonStartAttempted: false
  property bool wanted: false
  property string displayMode: "full" // "full" or "mini"
  property string miniScreenName: ""
  property string preferredScreenName: ""
  property var pinnedRaw: []

  readonly property string pluginId: manifest && manifest.id
    ? String(manifest.id) : "io.github.dankestrick.omapandora"
  readonly property string helper: Api.helperPath(Qt.resolvedUrl("../helpers/pithosctl"))
  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var pithosPlayer: findPithosPlayer()
  readonly property bool connected: !!(status && status.connected)
  readonly property bool playing: String(status.status || "") === "Playing"
    || !!(pithosPlayer && pithosPlayer.isPlaying)
  readonly property bool hasMedia: connected && (title !== "" || artist !== "")
  readonly property string title: String(status.title || (pithosPlayer ? pithosPlayer.trackTitle : "") || "")
  readonly property string artist: String(status.artist || (pithosPlayer ? pithosPlayer.trackArtist : "") || "")
  readonly property string album: String(status.album || (pithosPlayer ? pithosPlayer.trackAlbum : "") || "")
  readonly property string artUrl: String(status.artUrl || (pithosPlayer ? pithosPlayer.trackArtUrl : "") || "")
  readonly property string stationName: String(status.stationName || "")
  readonly property string stationPath: String(status.stationPath || "")
  readonly property var stations: status.stations instanceof Array ? status.stations : []
  readonly property bool loved: !!status.loved
  readonly property real volume: Number(status.volume || 0)
  readonly property bool volumeSupported: connected
  readonly property real positionSeconds: Number(status.positionMs || 0) / 1000
  readonly property real lengthSeconds: Number(status.lengthMs || 0) / 1000
  readonly property bool canGoNext: status.canGoNext !== false
  readonly property bool canGoPrevious: false
  readonly property bool showTrackTitle: Api.settingOn(setting("showTrackTitle", "On"), "On")
  readonly property bool showArtistName: Api.settingOn(setting("showArtistName", "Off"), "Off")
  readonly property bool showPausedTrack: Api.settingOn(setting("showPausedTrack", "On"), "On")
  readonly property bool scrollBarText: Api.settingOn(setting("scrollBarText", "Off"), "Off")
  readonly property real maxBarTextWidth: {
    var value = Number(setting("maxBarTextWidth", "240"))
    if (!isFinite(value)) return 240
    if (value <= 0) return 0
    return Math.max(160, Math.min(560, value))
  }
  readonly property bool fixedBarWidth: false
  readonly property var pinnedStations: {
    var saved = Api.parsePinnedStations(pinnedRaw)
    var live = stations
    var out = []
    for (var i = 0; i < saved.length; i++) {
      var item = saved[i] || {}
      var path = Api.stationPath(item)
      if (!path) continue
      var name = String(item.name || "")
      var id = String(item.id || "")
      for (var j = 0; j < live.length; j++) {
        if (String(live[j].path) === path) {
          name = live[j].name || name
          id = live[j].id || id
          break
        }
      }
      out.push({ path: path, name: name || "Station", id: id })
    }
    return out
  }
  readonly property var unpinnedStations: {
    var all = stations
    var out = []
    for (var i = 0; i < all.length; i++)
      if (!isPinned(all[i].path)) out.push(all[i])
    return out
  }

  function setting(key, fallback) {
    if (settings && settings[key] !== undefined && settings[key] !== null)
      return settings[key]
    return fallback
  }

  function applySettings(next) {
    if (next && typeof next === "object") settings = next
  }

  function findPithosPlayer() {
    for (var i = 0; i < players.length; i++) {
      var player = players[i]
      var dbus = String(player && player.dbusName || "").toLowerCase()
      var desktop = String(player && player.desktopEntry || "").toLowerCase()
      var identity = String(player && player.identity || "").toLowerCase()
      if (dbus.indexOf("pithos") !== -1 || desktop.indexOf("pithos") !== -1
          || identity.indexOf("pithos") !== -1)
        return player
    }
    return null
  }

  function setUiVisible(key, visible) {
    uiVisible = !!visible
    if (visible) {
      wanted = true
      autoplayArmed = true
      daemonStartAttempted = false
      refresh()
      ensureDaemon()
    }
  }

  function registerPlayerSurface(surface) {
    if (!surface) return
    if (playerSurfaces.indexOf(surface) === -1)
      playerSurfaces = playerSurfaces.concat([surface])
  }

  function unregisterPlayerSurface(surface) {
    playerSurfaces = playerSurfaces.filter(function(item) { return item !== surface })
  }

  function runHelper(args) {
    helperProc.command = [helper].concat(args)
    helperProc.running = true
  }

  function refresh() {
    statusProc.command = [helper, "status"]
    statusProc.running = true
  }

  function togglePlayback() {
    if (pithosPlayer && pithosPlayer.canTogglePlaying) pithosPlayer.togglePlaying()
    else runHelper(["playpause"])
    Qt.callLater(refresh)
  }

  function next() {
    if (pithosPlayer && pithosPlayer.canGoNext) pithosPlayer.next()
    else runHelper(["next"])
    Qt.callLater(refresh)
  }

  function love() { runHelper(["love"]); Qt.callLater(refresh) }
  function unrate() { runHelper(["unrate"]); Qt.callLater(refresh) }
  function toggleLove() { loved ? unrate() : love() }
  function ban() { runHelper(["ban"]); Qt.callLater(refresh) }
  function tired() { runHelper(["tired"]); Qt.callLater(refresh) }

  function setVolume(value) {
    runHelper(["volume", String(Api.clampUnit(value))])
    Qt.callLater(refresh)
  }

  function adjustVolume(delta) {
    setVolume(volume + delta)
  }

  function activateStation(path) {
    if (!path) return
    runHelper(["station", String(path)])
    Qt.callLater(refresh)
  }

  function isPinned(path) {
    var list = pinnedStations
    var key = String(path || "")
    for (var i = 0; i < list.length; i++)
      if (String(list[i].path) === key) return true
    return false
  }

  function togglePin(station) {
    if (!station) return
    var path = Api.stationPath(station)
    if (!path) return
    var saved = Api.parsePinnedStations(pinnedRaw)
    var next = []
    var found = false
    for (var i = 0; i < saved.length; i++) {
      var item = saved[i] || {}
      var itemPath = Api.stationPath(item)
      if (itemPath === path) {
        found = true
        continue
      }
      if (itemPath)
        next.push({
          path: itemPath,
          name: String(item.name || ""),
          id: String(item.id || "")
        })
    }
    if (!found)
      next.push({
        path: path,
        name: String(station.name || ""),
        id: String(station.id || "")
      })
    pinnedRaw = next
    var payload = JSON.stringify(next)
    pinFile.setText(payload)
    runHelper(["pins-save", payload])
  }

  function launchPithos() {
    lastError = ""
    daemonStartAttempted = true
    runHelper(["launch"])
    launchWatch.restart()
  }

  function ensureDaemon() {
    if (!wanted) return
    if (connected) {
      maybeAutoplay()
      return
    }
    launchPithos()
  }

  function stopAndQuit() {
    wanted = false
    autoplayArmed = false
    daemonStartAttempted = true
    launchWatch.stop()
    if (pithosPlayer) {
      if (pithosPlayer.canPause) pithosPlayer.pause()
      else if (pithosPlayer.canTogglePlaying && pithosPlayer.isPlaying)
        pithosPlayer.togglePlaying()
    }
    runHelper(["quit"])
  }

  function maybeAutoplay() {
    if (!autoplayArmed || !connected) return
    if (!playing) runHelper(["play"])
    autoplayArmed = false
  }

  function raisePithos() {
    if (connected) runHelper(["raise"])
    else launchPithos()
  }

  function focusedScreenName() {
    var monitor = Hyprland.focusedMonitor
    return monitor ? String(monitor.name || "") : ""
  }

  function rememberScreen(screenName) {
    var name = String(screenName || "")
    if (name) preferredScreenName = name
    if (!preferredScreenName) preferredScreenName = focusedScreenName()
    return preferredScreenName
  }

  function screenByName(name) {
    var want = String(name || "")
    if (!want) return null
    var screens = Quickshell.screens
    if (!screens) return null
    for (var i = 0; i < screens.length; i++) {
      if (screens[i] && String(screens[i].name) === want) return screens[i]
    }
    return null
  }

  function enterMini(screenName) {
    var name = rememberScreen(screenName)
    miniScreenName = name
    displayMode = "mini"
  }

  function openFullPlayer() {
    if (!shell) return
    rememberScreen(preferredScreenName || focusedScreenName())
    miniScreenName = ""
    displayMode = "full"
    if (typeof shell.summon === "function") shell.summon(pluginId, "{}")
    else if (typeof shell.toggle === "function") shell.toggle(pluginId, "{}")
  }

  function toggleDisplayMode() {
    if (displayMode === "full") enterMini(preferredScreenName)
    else {
      miniScreenName = ""
      displayMode = "full"
    }
  }

  function pinWindowToPreferredScreen() {
    var name = String(preferredScreenName || "")
    if (!name) return
    pinMonProc.command = [
      "hyprctl", "--batch",
      "dispatch focuswindow title:^(OmaPandora)$; "
        + "dispatch movewindow mon:" + name + "; "
        + "dispatch centerwindow"
    ]
    pinMonProc.running = true
  }

  IpcHandler {
    target: root.pluginId + ".player"
    function togglePlayer(): string {
      if (!root.shell) return "unavailable"
      if (typeof root.shell.toggle === "function") {
        root.shell.toggle(root.pluginId, "{}")
        return "ok"
      }
      return "unavailable"
    }
    function toggleMiniPlayer(): string { return togglePlayer() }
    function toggleFullPlayer(): string {
      root.openFullPlayer()
      return "ok"
    }
    function playPause(): string { root.togglePlayback(); return "ok" }
    function next(): string { root.next(); return "ok" }
    function love(): string { root.toggleLove(); return "ok" }
  }

  Process {
    id: statusProc
    stdout: StdioCollector { id: statusOut; waitForEnd: true }
    stderr: StdioCollector { id: statusErr; waitForEnd: true }
    onExited: function(code) {
      var parsed = Api.parseStatus(statusOut.text)
      if (parsed) {
        var wasConnected = root.connected
        root.status = parsed
        if (parsed.connected) {
          root.lastError = ""
          if (!wasConnected) root.maybeAutoplay()
        } else if (root.wanted && !root.daemonStartAttempted) {
          root.ensureDaemon()
        }
      } else if (code !== 0) {
        root.lastError = String(statusErr.text || "Could not read Pithos.").trim()
      }
    }
  }

  Process {
    id: helperProc
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { id: helperErr; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0)
        root.lastError = String(helperErr.text || "Pithos command failed.").trim()
      root.refresh()
    }
  }

  Process {
    id: pinMonProc
  }

  Timer {
    id: poll
    interval: root.uiVisible ? 1200 : 4000
    repeat: true
    running: true
    onTriggered: root.refresh()
  }

  Timer {
    id: launchWatch
    interval: 800
    repeat: true
    onTriggered: {
      root.refresh()
      if (root.connected) {
        stop()
        root.maybeAutoplay()
      }
    }
  }

  FileView {
    id: pinFile
    path: Quickshell.env("HOME") + "/.config/omarchy/omapandora-pins.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.pinnedRaw = Api.parsePinnedStations(text())
    onLoadFailed: root.pinnedRaw = []
  }

  Component.onCompleted: refresh()
  onPithosPlayerChanged: refresh()
}
