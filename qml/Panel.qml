import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui
import "Api.js" as Api

Item {
  id: root

  property var shell: null
  property var manifest: null
  property var service: null
  property bool opened: false
  property bool closingFromHost: false
  property string currentTab: "nowplaying"
  property string stationFilter: ""
  property real volumeBeforeMute: 0.5
  property int stationCursor: 0
  property int pinCursor: -1
  property string browseTarget: "nowplaying"
  property string focusRegion: "nowplaying"
  property bool shortcutHelpOpen: false

  readonly property string pluginId: manifest && manifest.id
    ? String(manifest.id) : "io.github.dankestrick.omapandora"
  readonly property color foreground: Color.foreground
  readonly property color background: Util.alpha(Color.background, 0.8)
  readonly property color accent: Color.accent
  readonly property color muted: Color.muted
  readonly property string fontFamily: Style.font.family
  readonly property bool connected: service && service.connected
  readonly property bool miniMode: !!(service && service.displayMode === "mini")
  readonly property var filteredStations: {
    var all = service && service.stations instanceof Array ? service.stations : []
    var needle = String(stationFilter || "").trim().toLowerCase()
    if (!needle) return all
    var out = []
    for (var i = 0; i < all.length; i++) {
      var name = String(all[i].name || "").toLowerCase()
      if (name.indexOf(needle) !== -1) out.push(all[i])
    }
    return out
  }
  readonly property var pinnedStations: copyStations(service ? service.pinnedStations : null)
  readonly property var unpinnedStations: copyStations(service ? service.unpinnedStations : null)
  readonly property var keyboardStations: unpinnedStations

  function applyPreferredScreen() {
    if (!service || typeof service.screenByName !== "function") return
    var name = service.preferredScreenName || service.focusedScreenName()
    var scr = service.screenByName(name)
    if (scr) window.screen = scr
  }

  function open(payloadJson) {
    closingFromHost = false
    if (service) service.displayMode = "full"
    applyPreferredScreen()
    opened = true
    if (service) service.setUiVisible("panel", true)
    browseTarget = "nowplaying"
    focusRegion = "nowplaying"
    currentTab = currentTab === "setup" ? "nowplaying" : currentTab
    if (currentTab === "stations") currentTab = "nowplaying"
    pinCursor = pinnedStations.length ? 0 : -1
    var list = keyboardStations
    var playingAt = service ? stationIndex(list, service.stationPath) : -1
    stationCursor = playingAt >= 0 ? playingAt : 0
    Qt.callLater(function() {
      root.applyPreferredScreen()
      if (root.service && typeof root.service.pinWindowToPreferredScreen === "function")
        root.service.pinWindowToPreferredScreen()
      keyRoot.forceActiveFocus()
    })
  }

  function close() {
    closingFromHost = true
    opened = false
    if (service) service.setUiVisible("panel", false)
    closingFromHost = false
  }

  function requestClose() {
    if (shell && typeof shell.hide === "function")
      shell.hide(pluginId)
    else close()
  }

  function stopAndClose() {
    if (service) service.stopAndQuit()
    requestClose()
  }

  function pageTitle() {
    if (currentTab === "stations") return "Stations"
    if (currentTab === "setup") return "Settings"
    var station = service && service.stationName ? String(service.stationName) : ""
    if (station) return "Now Playing - " + station
    return "Now Playing"
  }

  function chooseTab(id) { currentTab = id }

  function copyStations(src) {
    var out = []
    if (!src) return out
    for (var i = 0; i < src.length; i++) out.push(src[i])
    return out
  }

  function stationIndex(list, path) {
    var key = String(path || "")
    for (var i = 0; i < list.length; i++)
      if (String(list[i].path) === key) return i
    return -1
  }

  function cursorPath() {
    var list = keyboardStations
    if (!list.length) return ""
    var index = Math.max(0, Math.min(stationCursor, list.length - 1))
    return String(list[index].path || "")
  }

  function isCursor(path) {
    return browseTarget === "stations"
      && String(path || "") !== "" && String(path) === cursorPath()
  }

  function isPinnedCursor(index) {
    return browseTarget === "nowplaying" && Number(pinCursor) === Number(index)
  }

  function pinnedList() {
    var src = service && service.pinnedStations
    var out = []
    if (!src) return out
    for (var i = 0; i < src.length; i++) out.push(src[i])
    return out
  }

  function wrapIndex(index, length, delta) {
    if (length <= 0) return 0
    var pos = Math.round(Number(index) || 0) + delta
    while (pos < 0) pos += length
    while (pos >= length) pos -= length
    return pos
  }

  function moveStation(delta) {
    if (currentTab === "stations") currentTab = "nowplaying"
    if (browseTarget === "player") {
      setVolumeValue((service ? service.volume : 0) + (delta > 0 ? -0.05 : 0.05))
      return
    }
    if (browseTarget === "nowplaying") {
      var pins = pinnedList()
      if (!pins.length) return
      pinCursor = wrapIndex(pinCursor, pins.length, delta)
      Qt.callLater(function() { keyRoot.forceActiveFocus() })
      return
    }
    var list = keyboardStations
    if (!list.length) return
    stationCursor = wrapIndex(stationCursor, list.length, delta)
    Qt.callLater(scrollSidebarToCursor)
  }

  function scrollSidebarToCursor() {
    if (!unpinnedRepeater || !stationFlick) return
    var item = unpinnedRepeater.itemAt(stationCursor)
    if (!item) {
      if (stationCursor === 0) stationFlick.contentY = 0
      return
    }
    var maxY = Math.max(0, stationFlick.contentHeight - stationFlick.height)
    var y = item.y - Math.max(0, (stationFlick.height - item.height) / 2)
    stationFlick.contentY = Math.max(0, Math.min(maxY, y))
  }

  function activateCursorStation() {
    if (!service) return
    if (browseTarget === "player") {
      service.togglePlayback()
      return
    }
    if (browseTarget === "nowplaying") {
      var pins = pinnedList()
      if (pinCursor >= 0 && pinCursor < pins.length)
        service.activateStation(pins[pinCursor].path)
      return
    }
    var list = keyboardStations
    if (!list.length) return
    var index = Math.max(0, Math.min(stationCursor, list.length - 1))
    service.activateStation(list[index].path)
  }

  function focusSearch() {
    browseTarget = "stations"
    focusRegion = "search"
    if (currentTab === "stations") currentTab = "nowplaying"
    Qt.callLater(function() {
      if (stationSearch) stationSearch.forceActiveFocus()
    })
  }

  function frameSpec(active) {
    return Border.controlSpec(active ? "selected" : "normal", foreground, accent)
  }

  function cycleRegion() {
    var order = ["nowplaying", "stations", "player"]
    var at = order.indexOf(browseTarget)
    if (at < 0) at = 0
    browseTarget = order[(at + 1) % order.length]
    focusRegion = browseTarget
    if (browseTarget === "nowplaying")
      pinCursor = pinnedStations.length ? 0 : -1
    if (currentTab === "stations" || currentTab === "setup")
      currentTab = "nowplaying"
    Qt.callLater(function() {
      keyRoot.forceActiveFocus()
      if (root.browseTarget === "stations") root.scrollSidebarToCursor()
    })
  }

  function toggleMute() {
    if (!service) return
    if (service.volume > 0.001) {
      volumeBeforeMute = service.volume
      service.setVolume(0)
    } else service.setVolume(volumeBeforeMute || 0.5)
  }

  function pinCursorStation() {
    if (!service) return
    if (browseTarget === "nowplaying" && pinCursor >= 0
        && pinCursor < pinnedStations.length) {
      service.togglePin(pinnedStations[pinCursor])
      pinCursor = Math.min(pinCursor, Math.max(-1, pinnedStations.length - 2))
      return
    }
    if (browseTarget === "stations") {
      var list = keyboardStations
      if (list.length) {
        var index = Math.max(0, Math.min(stationCursor, list.length - 1))
        service.togglePin(list[index])
        return
      }
    }
    if (service.stationPath)
      service.togglePin({ path: service.stationPath, name: service.stationName })
  }

  function setVolumeValue(value) {
    if (!service) return
    if (value > 0.001) volumeBeforeMute = value
    service.setVolume(value)
  }

  onOpenedChanged: if (service) service.setUiVisible("panel", opened)
  onKeyboardStationsChanged: {
    if (stationCursor >= keyboardStations.length)
      stationCursor = Math.max(0, keyboardStations.length - 1)
  }

  Connections {
    target: root.service
    function onDisplayModeChanged() {
      if (root.service && root.service.displayMode === "mini" && root.opened)
        root.requestClose()
    }
  }

  FloatingWindow {
    id: window
    visible: root.opened
    title: "OmaPandora"
    color: root.background
    implicitWidth: 1440
    implicitHeight: 900
    minimumSize: Qt.size(1100, 700)

    onVisibleChanged: {
      if (!visible && root.opened && !root.closingFromHost)
        root.requestClose()
    }

    FocusScope {
      id: keyRoot
      anchors.fill: parent
      focus: true
      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        var ctrl = !!(event.modifiers & Qt.ControlModifier)
        var typing = stationSearch.activeFocus

        if (root.shortcutHelpOpen) {
          if (event.key === Qt.Key_Escape || (ctrl && event.key === Qt.Key_Slash)) {
            root.shortcutHelpOpen = false
            event.accepted = true
          }
          return
        }

        if (ctrl && event.key === Qt.Key_Slash) {
          root.shortcutHelpOpen = true
          event.accepted = true
        } else if (ctrl && event.key === Qt.Key_F) {
          root.focusSearch()
          event.accepted = true
        } else if (!typing && event.key === Qt.Key_Slash) {
          root.focusSearch()
          event.accepted = true
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_F6) {
          root.cycleRegion()
          event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
          root.requestClose()
          event.accepted = true
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
          root.moveStation(event.key === Qt.Key_Down ? 1 : -1)
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.activateCursorStation()
          event.accepted = true
        } else if (typing) {
          return
        } else if (event.key === Qt.Key_Space) {
          if (root.service) root.service.togglePlayback()
          event.accepted = true
        } else if (ctrl && event.key === Qt.Key_Right) {
          if (root.service) root.service.next()
          event.accepted = true
        } else if (ctrl && event.key === Qt.Key_Up) {
          root.setVolumeValue((root.service ? root.service.volume : 0) + 0.05)
          event.accepted = true
        } else if (ctrl && event.key === Qt.Key_Down) {
          root.setVolumeValue((root.service ? root.service.volume : 0) - 0.05)
          event.accepted = true
        } else if (event.key === Qt.Key_M) {
          root.toggleMute()
          event.accepted = true
        } else if (!ctrl && event.key === Qt.Key_C) {
          root.pinCursorStation()
          event.accepted = true
        }
      }

      Item {
        anchors.fill: parent
        anchors.margins: Style.space(14)

        Row {
          id: workspace
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: footerSeparator.top
          anchors.bottomMargin: Style.space(10)
          spacing: Style.space(10)

          BorderSurface {
            id: sidebar
            width: Math.min(Style.space(230), Math.max(Style.space(188), workspace.width * 0.24))
            height: parent.height
            color: "transparent"
            radius: Style.cornerRadius
            borderSpec: root.frameSpec(false)

            Column {
              anchors.fill: parent
              anchors.margins: Style.space(8)
              spacing: Style.space(8)

              Row {
                spacing: Style.space(8)
                OpticalGlyph {
                  width: Style.space(18)
                  height: Style.space(18)
                  text: "󰝚"
                  color: root.accent
                  fontFamily: root.fontFamily
                  fontSize: Style.font.icon
                }
                Text {
                  text: "OmaPandora"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              BorderSurface {
                width: parent.width
                implicitHeight: nowPlayCol.implicitHeight + Style.space(16)
                color: "transparent"
                radius: Style.cornerRadius
                borderSpec: root.frameSpec(root.browseTarget === "nowplaying")

                Column {
                  id: nowPlayCol
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.margins: Style.space(8)
                  spacing: Style.space(4)

                  Text {
                    text: "My list"
                    color: root.browseTarget === "nowplaying" ? root.accent : root.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: root.browseTarget === "nowplaying"
                  }

                  Text {
                    width: parent.width
                    visible: root.pinnedStations.length === 0
                    text: "Pin a station with C"
                    color: root.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.WordWrap
                  }

                  Repeater {
                    id: pinnedRepeater
                    model: root.pinnedStations.length
                    Button {
                      width: nowPlayCol.width
                      property int pinIndex: index
                      readonly property var pin: root.pinnedStations[pinIndex]
                      text: pin && pin.name ? pin.name : "Station"
                      iconText: "󰐃"
                      foreground: root.foreground
                      selected: root.isPinnedCursor(pinIndex)
                      onClicked: {
                        root.browseTarget = "nowplaying"
                        root.pinCursor = pinIndex
                        root.chooseTab("nowplaying")
                        if (root.service && pin) root.service.activateStation(pin.path)
                      }
                    }
                  }
                }
              }

              BorderSurface {
                width: parent.width
                height: Math.max(Style.space(120),
                  parent.height - nowPlayCol.implicitHeight - Style.space(120))
                color: "transparent"
                radius: Style.cornerRadius
                borderSpec: root.frameSpec(root.browseTarget === "stations")

                Column {
                  anchors.fill: parent
                  anchors.margins: Style.space(8)
                  spacing: Style.space(6)

                  Text {
                    text: "Your stations"
                    color: root.browseTarget === "stations" ? root.accent : root.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: root.browseTarget === "stations"
                    visible: root.connected && root.unpinnedStations.length > 0
                  }

                  Flickable {
                    id: stationFlick
                    width: parent.width
                    height: parent.height - Style.space(28)
                    clip: true
                    contentWidth: width
                    contentHeight: stationNav.implicitHeight
                    visible: root.connected
                    boundsBehavior: Flickable.StopAtBounds
                    focus: false
                    Keys.enabled: false

                    Column {
                      id: stationNav
                      width: parent.width
                      spacing: Style.space(2)

                      Repeater {
                        id: unpinnedRepeater
                        model: root.unpinnedStations
                        Button {
                          required property var modelData
                          width: stationNav.width
                          text: modelData.name || "Station"
                          foreground: root.foreground
                          selected: root.isCursor(modelData.path)
                          onClicked: {
                            root.stationCursor = root.stationIndex(root.keyboardStations, modelData.path)
                            root.browseTarget = "stations"
                            root.chooseTab("nowplaying")
                            if (root.service) root.service.activateStation(modelData.path)
                          }
                        }
                      }
                    }
                  }
                }
              }

              Button {
                width: parent.width
                text: "Settings"
                iconText: "󰒓"
                foreground: root.foreground
                selected: root.currentTab === "setup"
                onClicked: root.chooseTab("setup")
              }
            }
          }

          Item {
            width: parent.width - sidebar.width - parent.spacing
            height: parent.height

            Row {
              id: pageHeader
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              height: closeButton.implicitHeight
              spacing: Style.space(5)

              Row {
                width: Math.max(80, parent.width - headerMiniSwitch.width
                  - helpButton.width - refreshButton.width - closeButton.width
                  - parent.spacing * 4)
                spacing: Style.space(8)
                anchors.verticalCenter: parent.verticalCenter

                OpticalGlyph {
                  width: Style.space(22)
                  height: Style.space(22)
                  anchors.verticalCenter: parent.verticalCenter
                  text: "󰝚"
                  color: root.accent
                  fontFamily: root.fontFamily
                  fontSize: Style.font.title
                }

                Text {
                  width: Math.max(40, parent.width - Style.space(30))
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.pageTitle()
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.title
                  font.bold: true
                  elide: Text.ElideRight
                }
              }

              ToggleSwitch {
                id: headerMiniSwitch
                checked: root.miniMode
                foreground: root.foreground
                anchors.verticalCenter: parent.verticalCenter
                onToggled: {
                  if (!root.service) return
                  root.service.enterMini(root.service.preferredScreenName)
                }

                PanelToolTip {
                  visible: headerMiniSwitch.containsMouse
                  text: "Show mini player"
                  fontFamily: root.fontFamily
                }
              }

              Button {
                id: helpButton
                text: "?"
                foreground: root.foreground
                fontSize: Style.font.subtitle
                tooltipText: "Keyboard shortcuts · Ctrl+/"
                onClicked: root.shortcutHelpOpen = !root.shortcutHelpOpen
              }

              Button {
                id: refreshButton
                iconText: "󰑐"
                foreground: root.foreground
                tooltipText: "Refresh"
                onClicked: if (root.service) root.service.refresh()
              }

              Button {
                id: closeButton
                iconText: "󰅖"
                foreground: root.foreground
                tooltipText: "Close OmaPandora"
                onClicked: root.stopAndClose()
              }
            }

            TextField {
              id: stationSearch
              visible: root.currentTab === "stations"
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: pageHeader.bottom
              anchors.topMargin: visible ? Style.space(8) : 0
              height: visible ? Style.space(38) : 0
              foreground: root.foreground
              placeholderText: "Search stations"
              onTextEdited: root.stationFilter = text
            }

            Item {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: stationSearch.visible ? stationSearch.bottom : pageHeader.bottom
              anchors.topMargin: Style.space(10)
              anchors.bottom: parent.bottom

              BorderSurface {
                anchors.fill: parent
                visible: root.currentTab === "nowplaying"
                color: "transparent"
                radius: Style.cornerRadius
                borderSpec: root.frameSpec(root.browseTarget === "player")

                Row {
                  id: nowPlayingHeader
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.margins: Style.space(10)
                  spacing: Style.space(16)

                  BorderSurface {
                    width: Style.space(220)
                    height: width
                    radius: Style.cornerRadius
                    color: Style.selectedFillFor(root.foreground, root.accent)
                    borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

                    RetryImage {
                      id: heroArt
                      anchors.fill: parent
                      anchors.margins: Style.space(4)
                      requestedSource: root.opened && root.service ? root.service.artUrl : ""
                      fillMode: Image.PreserveAspectFit
                      asynchronous: true
                      cache: true
                      visible: status === Image.Ready
                    }

                    Text {
                      anchors.centerIn: parent
                      visible: heroArt.status !== Image.Ready
                      text: "󰎈"
                      color: root.muted
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.displayLarge
                    }
                  }

                  Column {
                    width: parent.width - Style.space(236)
                    spacing: Style.space(8)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                      width: parent.width
                      textFormat: Text.PlainText
                      text: root.service && root.service.title
                        ? root.service.title : "Nothing playing"
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.displayLarge
                      font.bold: true
                      wrapMode: Text.WordWrap
                    }

                    Text {
                      width: parent.width
                      visible: root.service && root.service.artist !== ""
                      textFormat: Text.PlainText
                      text: root.service ? root.service.artist : ""
                      color: root.accent
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.subtitle
                      wrapMode: Text.WordWrap
                    }

                    Text {
                      width: parent.width
                      visible: root.service && root.service.album !== ""
                      textFormat: Text.PlainText
                      text: root.service ? root.service.album : ""
                      color: root.muted
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                    }

                    Row {
                      width: parent.width
                      spacing: Style.space(8)
                      visible: root.service && root.service.stationName !== ""

                      Text {
                        width: Math.max(40, parent.width - pinCurrent.width - parent.spacing)
                        textFormat: Text.PlainText
                        text: root.service ? root.service.stationName : ""
                        color: root.muted
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.body
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                      }

                      Button {
                        id: pinCurrent
                        iconText: root.service && root.service.isPinned(root.service.stationPath)
                          ? "󰐃" : "󰤱"
                        foreground: root.foreground
                        tooltipText: root.service && root.service.isPinned(root.service.stationPath)
                          ? "Unpin from My list" : "Pin to My list"
                        onClicked: if (root.service)
                          root.service.togglePin({
                            path: root.service.stationPath,
                            name: root.service.stationName
                          })
                      }
                    }
                  }
                }

                Visualizer {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: parent.bottom
                  anchors.margins: Style.space(10)
                  height: Math.round(parent.height * 0.5)
                  playing: !!(root.service && root.service.playing)
                  active: root.opened && root.currentTab === "nowplaying"
                  barColor: root.accent
                  dimColor: root.muted
                }
              }

              Flickable {
                anchors.fill: parent
                visible: root.currentTab === "stations"
                clip: true
                contentWidth: width
                contentHeight: stationList.implicitHeight

                Column {
                  id: stationList
                  width: parent.width
                  spacing: Style.space(2)

                  Text {
                    visible: !root.connected
                    width: parent.width
                    text: "Open Pithos and sign in to load your stations."
                    color: root.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    wrapMode: Text.WordWrap
                  }

                  Repeater {
                    model: root.filteredStations
                    BorderSurface {
                      required property var modelData
                      width: stationList.width
                      height: Style.space(44)
                      radius: Style.spacing.labelGap
                      readonly property bool selected: root.service
                        && String(root.service.stationPath) === String(modelData.path)
                      readonly property bool cursor: {
                        var list = root.keyboardStations
                        var index = root.stationCursor
                        return index >= 0 && index < list.length
                          && String(list[index].path) === String(modelData.path)
                      }
                      color: selected
                        ? Style.selectedFillFor(root.foreground, root.accent)
                        : "transparent"
                      borderSpec: selected || cursor
                        ? Border.controlSpec("selected", root.foreground, root.accent)
                        : Border.none()

                      Row {
                        anchors.fill: parent
                        anchors.leftMargin: Style.space(8)
                        anchors.rightMargin: Style.space(8)
                        spacing: Style.space(10)

                        OpticalGlyph {
                          width: Style.space(18)
                          height: Style.space(18)
                          anchors.verticalCenter: parent.verticalCenter
                          text: "󰐹"
                          color: root.foreground
                          fontFamily: root.fontFamily
                          fontSize: Style.font.body
                        }

                        Text {
                          width: Math.max(40, parent.width - Style.space(110))
                          anchors.verticalCenter: parent.verticalCenter
                          textFormat: Text.PlainText
                          text: modelData.name || "Station"
                          color: root.foreground
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.body
                          elide: Text.ElideRight
                        }

                        Button {
                          anchors.verticalCenter: parent.verticalCenter
                          iconText: root.service && root.service.isPinned(modelData.path)
                            ? "󰐃" : "󰤱"
                          foreground: root.foreground
                          tooltipText: root.service && root.service.isPinned(modelData.path)
                            ? "Unpin from My list" : "Pin to My list"
                          onClicked: if (root.service) root.service.togglePin(modelData)
                        }

                        Button {
                          anchors.verticalCenter: parent.verticalCenter
                          iconText: "󰐊"
                          foreground: root.foreground
                          tooltipText: "Play station"
                          onClicked: if (root.service)
                            root.service.activateStation(modelData.path)
                        }
                      }

                      MouseArea {
                        anchors.fill: parent
                        z: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          root.stationCursor = root.stationIndex(root.keyboardStations, modelData.path)
                          if (root.service) root.service.activateStation(modelData.path)
                        }
                      }
                    }
                  }
                }
              }

              Column {
                anchors.fill: parent
                spacing: Style.space(12)
                visible: root.currentTab === "setup"

                Button {
                  text: "Open Pithos"
                  iconText: "󰍂"
                  foreground: root.foreground
                  onClicked: if (root.service) root.service.raisePithos()
                }

                Text {
                  width: parent.width
                  visible: root.service && root.service.lastError !== ""
                  textFormat: Text.PlainText
                  text: root.service ? root.service.lastError : ""
                  color: Color.urgent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }
              }
            }
          }
        }

        PanelSeparator {
          id: footerSeparator
          visible: true
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: playerFooter.top
          anchors.bottomMargin: Style.space(4)
          foreground: root.foreground
        }

        BorderSurface {
          id: playerFooter
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: Style.space(92)
          color: "transparent"
          radius: Style.cornerRadius
          borderSpec: root.frameSpec(root.browseTarget === "player")

          Row {
            id: playerRow
            anchors.fill: parent
            anchors.margins: Style.space(6)
            spacing: Style.space(12)

            Item {
              width: Math.max(Style.space(170), Math.min(Style.space(240), playerRow.width * 0.29))
              height: parent.height

              BorderSurface {
                id: footerArt
                width: Math.min(parent.height, Style.space(68))
                height: width
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                radius: Style.cornerRadius
                color: Style.selectedFillFor(root.foreground, root.accent)
                borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

                RetryImage {
                  id: footerArtImage
                  anchors.fill: parent
                  anchors.margins: Style.space(2)
                  requestedSource: root.service ? root.service.artUrl : ""
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                  cache: true
                  visible: status === Image.Ready
                }

                Text {
                  anchors.centerIn: parent
                  visible: footerArtImage.status !== Image.Ready
                  text: "󰎈"
                  color: root.muted
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.iconLarge
                }
              }

              Column {
                anchors.left: footerArt.right
                anchors.leftMargin: Style.space(9)
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(3)

                Row {
                  width: parent.width
                  spacing: Style.space(3)
                  Text {
                    width: Math.max(20, parent.width - footerLike.width - parent.spacing)
                    textFormat: Text.PlainText
                    text: root.service && root.service.title
                      ? root.service.title : "Nothing playing"
                    color: root.service && root.service.title ? root.foreground : root.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                    elide: Text.ElideRight
                  }
                  Button {
                    id: footerLike
                    iconText: root.service && root.service.loved ? "󰋑" : "󰋕"
                    iconSize: Style.font.body
                    foreground: Color.urgent
                    accent: Color.urgent
                    enabled: root.connected && root.service && root.service.hasMedia
                    horizontalPadding: Style.space(4)
                    verticalPadding: Style.space(2)
                    onClicked: if (root.service) root.service.toggleLove()
                  }
                }

                Text {
                  width: parent.width
                  textFormat: Text.PlainText
                  text: root.service && root.service.artist
                    ? root.service.artist : "Choose a station to play"
                  color: root.service && root.service.artist ? root.accent : root.muted
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }
            }

            Item {
              width: Math.max(Style.space(240), playerRow.width * 0.42)
              height: parent.height

              Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: Style.space(4)

                Row {
                  anchors.horizontalCenter: parent.horizontalCenter
                  spacing: Style.space(5)

                  TransportButton {
                    glyphText: "󰥊"
                    foreground: root.foreground
                    tooltipText: "Tired"
                    enabled: root.connected && root.service && root.service.hasMedia
                    onClicked: if (root.service) root.service.tired()
                  }
                  TransportButton {
                    glyphText: "󰒮"
                    foreground: root.foreground
                    enabled: false
                    opacity: 0.35
                  }
                  TransportButton {
                    glyphText: root.service && root.service.playing ? "󰏤" : "󰐊"
                    glyphSize: Style.font.iconLarge
                    foreground: root.foreground
                    selected: true
                    onClicked: if (root.service) root.service.togglePlayback()
                  }
                  TransportButton {
                    glyphText: "󰒭"
                    foreground: root.foreground
                    tooltipText: "Skip"
                    enabled: root.connected && root.service && root.service.canGoNext
                    onClicked: if (root.service) root.service.next()
                  }
                  TransportButton {
                    glyphText: "󰅙"
                    foreground: root.foreground
                    tooltipText: "Ban"
                    enabled: root.connected && root.service && root.service.hasMedia
                    onClicked: if (root.service) root.service.ban()
                  }
                }

                Row {
                  width: parent.width
                  spacing: Style.space(8)
                  visible: root.service && root.service.lengthSeconds > 0
                  Text {
                    text: Api.millisecondsToClock((root.service ? root.service.positionSeconds : 0) * 1000)
                    color: root.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  PlaybackSlider {
                    width: parent.width - Style.space(90)
                    bar: null
                    minimum: 0
                    maximum: Math.max(1, root.service ? root.service.lengthSeconds : 1)
                    sourceValue: root.service ? root.service.positionSeconds : 0
                    enabled: false
                  }
                  Text {
                    text: Api.millisecondsToClock((root.service ? root.service.lengthSeconds : 0) * 1000)
                    color: root.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
              }
            }

            Item {
              width: Math.max(Style.space(140), playerRow.width * 0.22)
              height: parent.height

              Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: Style.space(8)

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.service && root.service.volume <= 0.001 ? "󰝟" : "󰕾"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.icon
                }

                PlaybackSlider {
                  width: parent.width - Style.space(34)
                  anchors.verticalCenter: parent.verticalCenter
                  minimum: 0
                  maximum: 1
                  step: 0.05
                  sourceValue: root.service ? root.service.volume : 0
                  liveCommit: true
                  enabled: root.connected
                  onCommitted: function(value) { root.setVolumeValue(value) }
                }
              }
            }
          }
        }
      }

      Rectangle {
        anchors.fill: parent
        visible: root.shortcutHelpOpen
        color: Util.alpha(Color.background, 0.82)
        z: 20

        MouseArea {
          anchors.fill: parent
          onClicked: root.shortcutHelpOpen = false
        }

        BorderSurface {
          anchors.centerIn: parent
          width: Math.min(parent.width - Style.space(80), Style.space(560))
          height: helpColumn.implicitHeight + Style.space(32)
          radius: Style.cornerRadius
          color: Util.alpha(Color.background, 0.94)
          borderSpec: Border.controlSpec("normal", root.foreground, root.accent)

          Column {
            id: helpColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(16)
            spacing: Style.space(8)

            Text {
              text: "Keyboard shortcuts"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Repeater {
              model: [
                "Ctrl+F or / — Search stations",
                "Tab / F6 — My list, Your stations, then the big player",
                "Arrow keys — Move inside the Tab group",
                "Enter — Play the highlighted station",
                "C — Pin or unpin the highlighted station",
                "Space — Play or pause",
                "Ctrl+Right — Next song",
                "Ctrl+Up / Ctrl+Down — Volume",
                "M — Mute or restore volume",
                "Ctrl+/ — This list",
                "Esc — Close the player"
              ]
              Text {
                required property string modelData
                width: helpColumn.width
                text: modelData
                color: root.muted
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                wrapMode: Text.WordWrap
              }
            }
          }
        }
      }
    }
  }
}
