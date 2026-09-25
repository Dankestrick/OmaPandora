import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Api.js" as Api

BarWidget {
  id: root
  moduleName: "io.github.dankestrick.omapandora"

  readonly property var pandora: bar && bar.shell
    ? bar.shell.serviceFor("io.github.dankestrick.omapandora") : null
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color muted: Color.muted
  readonly property string barText: pandora
    ? Api.barTrackText(pandora.title, pandora.artist,
      pandora.showTrackTitle, pandora.showArtistName, pandora.playing,
      pandora.showPausedTrack) : ""
  readonly property bool miniPlayerEnabled:
    String(root.setting("showMiniPlayer", "On")) !== "Off"
  readonly property bool iconOnly: !pandora || vertical || !pandora.hasMedia
    || barText === ""
  property bool popupOpen: false
  property real volumeBeforeMute: 0.5
  readonly property bool panelOpen: bar && bar.shell
    && typeof bar.shell.isPluginOpen === "function"
    && bar.shell.isPluginOpen(moduleName)
  readonly property bool opened: popupOpen

  function setting(key, fallback) {
    if (settings && settings[key] !== undefined && settings[key] !== null)
      return settings[key]
    return fallback
  }

  function open() {
    if (miniPlayerEnabled) openMiniPopup()
    else openFullPanel()
  }
  function close() {
    popupOpen = false
    if (bar && bar.shell && typeof bar.shell.hide === "function"
        && bar.shell.isPluginOpen && bar.shell.isPluginOpen(moduleName))
      bar.shell.hide(moduleName)
  }
  function toggle() {
    if (!miniPlayerEnabled) {
      openFullPanel()
      return
    }
    if (popupOpen) {
      popupOpen = false
      return
    }
    openMiniPopup()
  }
  function closeForPopoutSwitch() { popupOpen = false }

  function thisScreenName() {
    var win = root.QsWindow ? root.QsWindow.window : null
    return win && win.screen ? String(win.screen.name || "") : ""
  }

  function ownsMini() {
    if (!pandora) return false
    var here = thisScreenName()
    var want = String(pandora.miniScreenName || "")
    if (want) return here === want
    if (bar && typeof bar.focusedScreenName === "function") {
      var focused = String(bar.focusedScreenName() || "")
      if (focused) return here === focused
    }
    return false
  }

  function hideFullPanel() {
    var host = bar ? bar.shell : null
    if (host && typeof host.isPluginOpen === "function" && host.isPluginOpen(moduleName)
        && typeof host.hide === "function")
      host.hide(moduleName)
  }

  function stopAndClose() {
    if (pandora) pandora.stopAndQuit()
    popupOpen = false
    hideFullPanel()
  }

  function syncMiniPopup() {
    if (pandora && pandora.displayMode === "mini" && miniPlayerEnabled && ownsMini()) {
      hideFullPanel()
      popupOpen = true
    } else {
      popupOpen = false
    }
  }

  function openMiniPopup() {
    if (pandora && typeof pandora.enterMini === "function")
      pandora.enterMini(thisScreenName())
    else if (pandora)
      pandora.displayMode = "mini"
    syncMiniPopup()
  }

  function openFullPanel() {
    popupOpen = false
    if (pandora) {
      if (typeof pandora.rememberScreen === "function")
        pandora.rememberScreen(thisScreenName())
      pandora.miniScreenName = ""
      pandora.displayMode = "full"
    }
    var host = bar ? bar.shell : null
    if (!host) return
    if (typeof host.isPluginOpen === "function" && host.isPluginOpen(moduleName))
      return
    if (typeof host.summon === "function") host.summon(moduleName, "{}")
    else if (typeof host.show === "function") host.show(moduleName)
  }

  function setVolumeValue(value) {
    if (!pandora) return
    if (value > 0.001) volumeBeforeMute = value
    pandora.setVolume(value)
  }

  function toggleMute() {
    if (!pandora) return
    if (pandora.volume > 0.001) {
      volumeBeforeMute = pandora.volume
      pandora.setVolume(0)
    } else pandora.setVolume(volumeBeforeMute || 0.5)
  }

  function syncSettings() {
    if (pandora) pandora.applySettings(settings)
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onSettingsChanged: syncSettings()
  onPandoraChanged: {
    syncSettings()
    if (pandora) pandora.registerPlayerSurface(root)
  }
  onPopupOpenChanged: if (pandora) pandora.setUiVisible("mini", popupOpen)
  onMiniPlayerEnabledChanged: if (!miniPlayerEnabled) popupOpen = false

  Connections {
    target: root.pandora
    function onDisplayModeChanged() { root.syncMiniPopup() }
    function onMiniScreenNameChanged() { root.syncMiniPopup() }
  }
  Component.onCompleted: {
    syncSettings()
    if (pandora) pandora.registerPlayerSurface(root)
  }
  Component.onDestruction: if (pandora) {
    pandora.setUiVisible("mini", false)
    pandora.unregisterPlayerSurface(root)
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.iconOnly ? "󰝚" : ""
    hasVisualContent: true
    slotSize: Style.bar.iconSlot
    opticalSize: Style.bar.iconCanvas
    fontSize: root.iconOnly ? Math.round(Style.bar.iconFont * 0.9) : Style.font.body
    active: root.pandora && root.pandora.playing
    foreground: root.bar ? root.bar.barForeground : root.foreground
    activeColor: foreground
    tooltipText: "OmaPandora"

    readonly property real fittedWidth: Math.ceil(barGlyph.width
      + barContent.spacing + barLabel.implicitWidth + scaledHorizontalMargin * 2)
    readonly property real barTextCap: root.pandora ? root.pandora.maxBarTextWidth : 240

    fixedWidth: root.vertical ? root.barSize
      : (root.iconOnly ? Style.bar.iconSlot
        : Api.barSlotWidth(false, barTextCap > 0 ? Style.space(barTextCap) : 0,
          fittedWidth, root.barSize))
    fixedHeight: root.vertical && root.iconOnly ? Style.bar.iconSlot : -1
    clip: true

    Row {
      id: barContent
      anchors.centerIn: parent
      spacing: Style.space(6)
      visible: !root.iconOnly
      enabled: false

      OpticalGlyph {
        id: barGlyph
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(16)
        height: Style.space(16)
        text: "󰝚"
        color: button.foreground
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        fontSize: Style.font.body
      }

      Item {
        id: scrollClip
        width: Math.max(0, button.width - barGlyph.width
          - barContent.spacing - button.scaledHorizontalMargin * 2)
        height: barGlyph.height
        anchors.verticalCenter: parent.verticalCenter
        clip: true

        Text {
          id: barLabel
          anchors.verticalCenter: parent.verticalCenter
          text: root.barText
          color: button.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          renderType: Text.NativeRendering

          XAnimator on x {
            running: root.pandora && root.pandora.scrollBarText
              && implicitWidth > scrollClip.width && !root.popupOpen && !root.vertical
            loops: Animation.Infinite
            duration: Math.round(Math.max(6000, implicitWidth * 25))
            from: scrollClip.width
            to: -implicitWidth
            easing.type: Easing.Linear
            onStopped: barLabel.x = 0
          }
        }
      }
    }

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.MiddleButton) {
        if (root.pandora) root.pandora.togglePlayback()
      } else if (mouseButton === Qt.RightButton) {
        root.openFullPanel()
      } else root.toggle()
    }
    onWheelMoved: function(delta) {
      if (!root.pandora) return
      if (delta < 0) root.pandora.next()
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: fittedContentWidth(Style.space(380))
    contentHeight: fittedContentHeight(contentColumn.implicitHeight, Style.space(560))

    Column {
      id: contentColumn
      anchors.fill: parent
      spacing: Style.space(12)

      Row {
        width: parent.width
        spacing: Style.space(10)

        Text {
          id: heroIcon
          textFormat: Text.PlainText
          text: "󰝚"
          color: root.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.display
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          id: heroLabels
          width: Math.max(40, parent.width - heroIcon.width - miniClose.width
            - miniSwitch.width - parent.spacing * 3)
          spacing: Style.space(2)
          anchors.verticalCenter: parent.verticalCenter

          Text {
            width: parent.width
            text: "OmaPandora"
            color: root.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: {
              if (root.pandora && root.pandora.stationName)
                return String(root.pandora.stationName).toUpperCase()
              if (root.pandora && root.pandora.playing) return "PLAYING"
              return "READY"
            }
            color: Qt.darker(root.foreground, 1.4)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
            elide: Text.ElideRight
          }
        }

        Button {
          id: miniClose
          iconText: "󰅖"
          foreground: root.foreground
          tooltipText: "Close OmaPandora"
          anchors.verticalCenter: parent.verticalCenter
          onClicked: root.stopAndClose()
        }

        ToggleSwitch {
          id: miniSwitch
          checked: root.pandora ? root.pandora.displayMode === "mini" : true
          foreground: root.foreground
          anchors.verticalCenter: parent.verticalCenter
          onToggled: root.openFullPanel()

          PanelToolTip {
            visible: miniSwitch.containsMouse
            text: "Open full player"
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }
        }
      }

      Column {
        width: parent.width
        spacing: Style.space(8)
        visible: !root.pandora || !root.pandora.connected

        Button {
          text: "Open Pithos"
          iconText: "󰍂"
          foreground: root.foreground
          onClicked: if (root.pandora) root.pandora.launchPithos()
        }
      }

      Item {
        id: miniNowPlaying
        width: parent.width
        implicitHeight: Math.max(miniArtwork.height, miniMeta.implicitHeight)
        height: implicitHeight
        visible: root.pandora && root.pandora.connected

        BorderSurface {
          id: miniArtwork
          width: Style.space(78)
          height: width
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          radius: Style.cornerRadius
          color: Style.normalFillFor(root.foreground, Color.accent)
          borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)

          RetryImage {
            id: miniArt
            anchors.fill: parent
            anchors.margins: Style.space(3)
            requestedSource: root.popupOpen && root.pandora ? root.pandora.artUrl : ""
            sourceSize.width: 156
            sourceSize.height: 156
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: true
            visible: status === Image.Ready
          }

          Text {
            anchors.centerIn: parent
            visible: miniArt.status !== Image.Ready
            text: "󰝚"
            color: root.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.displayLarge
          }
        }

        Column {
          id: miniMeta
          anchors.left: miniArtwork.right
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: Style.space(12)
          spacing: Style.space(4)

          Row {
            width: parent.width
            spacing: Style.space(4)

            Text {
              width: Math.max(20, parent.width - likeButton.width - parent.spacing)
              text: root.pandora && root.pandora.title ? root.pandora.title : "Nothing playing"
              color: root.pandora && root.pandora.title ? root.foreground : root.muted
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.subtitle
              font.bold: true
              elide: Text.ElideRight
            }

            Button {
              id: likeButton
              iconText: root.pandora && root.pandora.loved ? "󰋑" : "󰋕"
              iconSize: Style.font.body
              foreground: Color.urgent
              accent: Color.urgent
              enabled: root.pandora && root.pandora.hasMedia
              horizontalPadding: Style.space(4)
              verticalPadding: Style.space(2)
              tooltipText: root.pandora && root.pandora.loved ? "Loved" : "Love this song"
              onClicked: if (root.pandora) root.pandora.toggleLove()
            }
          }

          Text {
            width: parent.width
            visible: root.pandora && root.pandora.artist !== ""
            text: root.pandora ? root.pandora.artist : ""
            color: Color.accent
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            visible: root.pandora && (root.pandora.album !== "" || root.pandora.stationName !== "")
            text: root.pandora
              ? (root.pandora.album || root.pandora.stationName) : ""
            color: root.muted
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }
      }

      Column {
        width: parent.width
        spacing: Style.space(3)
        visible: root.pandora && root.pandora.connected && root.pandora.lengthSeconds > 0

        PlaybackSlider {
          width: parent.width
          bar: root.bar
          minimum: 0
          maximum: Math.max(1, root.pandora ? root.pandora.lengthSeconds : 1)
          sourceValue: root.pandora ? root.pandora.positionSeconds : 0
          enabled: false
          step: 5
        }

        Row {
          width: parent.width
          Text {
            text: Api.millisecondsToClock((root.pandora ? root.pandora.positionSeconds : 0) * 1000)
            color: root.muted
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Item { width: Math.max(0, parent.width - Style.space(80)); height: 1 }
          Text {
            text: Api.millisecondsToClock((root.pandora ? root.pandora.lengthSeconds : 0) * 1000)
            color: root.muted
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(5)
        visible: root.pandora && root.pandora.connected

        TransportButton {
          glyphText: "󰥊"
          foreground: root.foreground
          tooltipText: "Tired of this song"
          enabled: root.pandora && root.pandora.hasMedia
          onClicked: if (root.pandora) root.pandora.tired()
        }

        TransportButton {
          glyphText: "󰒮"
          foreground: root.foreground
          tooltipText: "Previous is not available on Pandora"
          enabled: false
          opacity: 0.35
        }

        TransportButton {
          glyphText: root.pandora && root.pandora.playing ? "󰏤" : "󰐊"
          glyphSize: Style.font.iconLarge
          foreground: root.foreground
          selected: true
          tooltipText: root.pandora && root.pandora.playing ? "Pause" : "Play"
          onClicked: if (root.pandora) root.pandora.togglePlayback()
        }

        TransportButton {
          glyphText: "󰒭"
          foreground: root.foreground
          tooltipText: "Skip"
          enabled: root.pandora && root.pandora.canGoNext
          onClicked: if (root.pandora) root.pandora.next()
        }

        TransportButton {
          glyphText: "󰅙"
          foreground: root.foreground
          tooltipText: "Ban this song"
          enabled: root.pandora && root.pandora.hasMedia
          onClicked: if (root.pandora) root.pandora.ban()
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(8)
        visible: root.pandora && root.pandora.connected

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.pandora && root.pandora.volume <= 0.001 ? "󰝟" : "󰕾"
          color: root.pandora && root.pandora.volume <= 0.001 ? root.muted : root.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.icon
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleMute()
          }
        }

        PlaybackSlider {
          width: parent.width - Style.space(34)
          anchors.verticalCenter: parent.verticalCenter
          bar: root.bar
          minimum: 0
          maximum: 1
          step: 0.05
          sourceValue: root.pandora ? root.pandora.volume : 0
          liveCommit: true
          onCommitted: function(value) { root.setVolumeValue(value) }
        }
      }

    }
  }
}
