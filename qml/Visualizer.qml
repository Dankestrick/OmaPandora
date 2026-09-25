import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "Api.js" as Api

Item {
  id: root

  property bool playing: false
  property bool active: visible
  property color barColor: Color.accent
  property color dimColor: Color.muted
  property int barCount: 56

  property var levels: blankLevels()

  readonly property string runner: Api.helperPath(Qt.resolvedUrl("../helpers/cava-run"))

  function blankLevels() {
    var out = []
    for (var i = 0; i < barCount; i++) out.push(0.06)
    return out
  }

  function parseFrame(line) {
    var parts = String(line || "").replace(/;+$/, "").trim().split(";")
    if (parts.length < 8) return
    var next = []
    for (var i = 0; i < root.barCount; i++) {
      var raw = Number(parts[i] || 0)
      if (!isFinite(raw)) raw = 0
      next.push(Math.max(0.03, Math.min(1, raw / 72)))
    }
    levels = next
  }

  Process {
    id: cavaProc
    command: [root.runner]
    running: root.active && root.playing
    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(line) { root.parseFrame(line) }
    }
  }

  onPlayingChanged: if (!playing) levels = blankLevels()

  Row {
    id: row
    anchors.fill: parent
    spacing: Math.max(1, Math.floor(width / root.barCount * 0.22))

    Repeater {
      model: root.barCount
      Rectangle {
        required property int index
        width: Math.max(3, Math.floor((row.width - row.spacing * (root.barCount - 1)) / root.barCount))
        height: Math.max(6, parent.height * (root.levels[index] || 0.03))
        anchors.bottom: parent.bottom
        radius: Math.max(1, width / 2)
        color: root.playing ? root.barColor : root.dimColor
        opacity: root.playing ? 0.95 : 0.28

        Behavior on height {
          NumberAnimation { duration: 70; easing.type: Easing.OutQuad }
        }
      }
    }
  }
}
