pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.sidebar

// Slide-in control centre on the right edge of the focused monitor. Everything
// in it is a card; adding one is a file in modules/sidebar/ and a line below.
Singleton {
    id: root

    readonly property bool shown: SidebarState.shown
    readonly property int panelWidth: 420

    // The toggle tiles read their state from mw-* commands. Only poll while
    // the panel is actually on screen.
    onShownChanged: Toggles.watching = root.shown

    LazyLoader {
        activeAsync: root.shown

        PanelWindow {
            id: win
            WlrLayershell.namespace: "mw-sidebar"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors { top: true; bottom: true; right: true }
            implicitWidth: root.panelWidth + 16
            color: "transparent"
            exclusiveZone: 0

            HyprlandFocusGrab {
                windows: [win]
                active: root.shown
                onCleared: SidebarState.hide()
            }

            Rectangle {
                id: panel
                width: root.panelWidth
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 8
                radius: Config.radius * 2
                color: Qt.alpha(Theme.bg, 0.97)
                border.width: 1
                border.color: Theme.overlay

                // Slides in from the right rather than appearing.
                transform: Translate {
                    x: root.shown ? 0 : root.panelWidth + 16
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 12
                    contentHeight: cards.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: cards
                        width: parent.width
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.bottomMargin: 2

                            Text {
                                Layout.fillWidth: true
                                text: Qt.formatDateTime(clock.date, Config.dateFormat)
                                color: Theme.fg
                                font.family: Config.font
                                font.pixelSize: Config.fontSize + 2
                                font.bold: true
                            }
                            Text {
                                text: Qt.formatDateTime(clock.date, Config.timeFormat)
                                color: Theme.accent
                                font.family: Config.font
                                font.pixelSize: Config.fontSize + 2
                            }
                        }

                        TogglesCard {}
                        MediaCard {}
                        WeatherCard {}
                        NotificationsCard {}
                    }
                }

                SystemClock { id: clock; precision: SystemClock.Minutes }
            }
        }
    }
}
