pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs
import qs.services

// Volume and brightness feedback. Replaces swayosd. Shown on request from the
// mw-audio / mw-brightness commands rather than by watching for changes, so
// adjusting volume from elsewhere doesn't pop an overlay in your face.
Singleton {
    id: root

    property bool shown: false
    property string kind: "audio"
    property int value: 0
    property string icon: ""

    function showAudio() {
        const sink = Pipewire.defaultAudioSink;
        const muted = sink?.audio?.muted ?? false;
        value = sink?.audio ? Math.round(sink.audio.volume * 100) : 0;
        icon = muted ? "󰝟" : value > 50 ? "󰕾" : value > 0 ? "󰖀" : "󰕿";
        kind = "audio"; shown = true; hide.restart();
    }

    function showBrightness() {
        icon = "󰃠"; kind = "brightness"; shown = true; hide.restart();
        brightness.running = true;
    }

    Process {
        id: brightness
        command: ["mw-brightness", "get"]
        stdout: StdioCollector {
            onStreamFinished: root.value = Number(this.text.trim()) || 0
        }
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    Timer { id: hide; interval: 1800; onTriggered: root.shown = false }

    LazyLoader {
        activeAsync: root.shown

        PanelWindow {
            WlrLayershell.namespace: "mw-osd"
            WlrLayershell.layer: WlrLayer.Overlay
            anchors { bottom: true }
            margins.bottom: 120
            implicitWidth: 280
            implicitHeight: 64
            color: "transparent"
            exclusiveZone: 0

            Rectangle {
                anchors.fill: parent
                radius: Config.radius * 2
                color: Qt.alpha(Theme.bg, 0.95)
                border.width: 2
                border.color: Theme.accent

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: root.icon
                        color: Theme.accent
                        font.family: Config.font
                        font.pixelSize: 22
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: 3
                        color: Theme.surface

                        Rectangle {
                            width: parent.width * Math.min(root.value, 100) / 100
                            height: parent.height
                            radius: 3
                            color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 90 } }
                        }
                    }

                    Text {
                        text: root.value + "%"
                        color: Theme.fg
                        font.family: Config.font
                        font.pixelSize: Config.fontSize + 1
                    }
                }
            }
        }
    }
}
