import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs
import qs.services

Card {
    id: root
    title: "Playing"

    // Whatever is actually playing wins; otherwise the first player that
    // exists, so the card still shows a paused track.
    readonly property var player: {
        const ps = Mpris.players?.values ?? [];
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null;
    }

    visible: player !== null

    ColumnLayout {
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                implicitWidth: 56; implicitHeight: 56
                radius: Config.radius
                color: Theme.surface
                clip: true

                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    source: root.player?.trackArtUrl ?? ""
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.player?.trackArtUrl
                    text: "󰎈"
                    color: Theme.fgDim
                    font.family: Config.font
                    font.pixelSize: 22
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle ?? ""
                    color: Theme.fg
                    elide: Text.ElideRight
                    font.family: Config.font
                    font.pixelSize: Config.fontSize
                }
                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackArtist ?? ""
                    color: Theme.fgDim
                    elide: Text.ElideRight
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 2
                }
                Text {
                    Layout.fillWidth: true
                    text: root.player?.identity ?? ""
                    color: Theme.fgDim
                    elide: Text.ElideRight
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 3
                }
            }
        }

        // Progress. Mpris exposes position in seconds; poll while visible.
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: Theme.surface
            visible: (root.player?.length ?? 0) > 0

            Rectangle {
                width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                height: parent.height
                radius: 2
                color: Theme.accent
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18

            Repeater {
                model: [
                    { icon: "󰒮", act: "previous" },
                    { icon: "play",  act: "toggle" },
                    { icon: "󰒭", act: "next" }
                ]

                delegate: Text {
                    required property var modelData
                    text: modelData.act === "toggle"
                        ? (root.player?.isPlaying ? "󰏤" : "󰐊")
                        : modelData.icon
                    color: mouse.containsMouse ? Theme.accent : Theme.fg
                    font.family: Config.font
                    font.pixelSize: modelData.act === "toggle" ? 24 : 19

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        onClicked: {
                            if (!root.player) return;
                            if (modelData.act === "next") root.player.next();
                            else if (modelData.act === "previous") root.player.previous();
                            else root.player.togglePlaying();
                        }
                    }
                }
            }
        }
    }

    // Keeps the scrubber moving without polling when the sidebar is shut.
    Timer {
        running: root.visible && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        onTriggered: root.player?.positionChanged()
    }
}
