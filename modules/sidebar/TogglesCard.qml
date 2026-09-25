import QtQuick
import QtQuick.Layouts
import qs
import qs.services

Card {
    title: "Quick settings"

    // Tiles come in two kinds. A toggle reads its state back from the same
    // mw-* command a keybinding would run and fills with the accent colour
    // while it is on, so you can tell at a glance; it leaves the sidebar open
    // so you actually see the change. An action just does the thing and gets
    // out of the way.
    GridLayout {
        columns: 3
        columnSpacing: 8
        rowSpacing: 8

        Repeater {
            model: [
                { icon: "󰌵", label: "Night",     cmd: ["mw-nightlight", "toggle"],      state: "nightlight" },
                { icon: "󰅶", label: "Idle lock", cmd: ["mw-idle", "toggle"],            state: "idleLock" },
                { icon: "󰍹", label: "HDR",       cmd: ["mw-monitor", "hdr", "toggle"],  state: "hdr" },

                { icon: "󰝟", label: "Mute",      cmd: ["mw-audio", "mute"],             state: "muted" },
                { icon: "󰓃", label: "Audio",     cmd: ["mw-audio", "menu"] },
                { icon: "󰂯", label: "Bluetooth", cmd: ["ghostty", "-e", "bluetui"] },

                { icon: "󰅍", label: "Clipboard", cmd: ["mw-clipboard", "show"] },
                { icon: "󰸉", label: "Wallpaper", cmd: ["mw-background", "next"],        keepOpen: true },
                { icon: "󰏘", label: "Theme",     cmd: ["mw-theme", "menu"] },

                { icon: "󰖯", label: "Windows",   cmd: ["mw-menu", "toggle", "windows"] },
                { icon: "󰍺", label: "Display",   cmd: ["mw-menu", "toggle", "display"] },
                { icon: "󰄀", label: "Capture",   cmd: ["mw-menu", "toggle", "capture"] },

                { icon: "󱓞", label: "Apps",      cmd: ["mw-menu", "toggle", "apps"] },
                { icon: "󰌾", label: "Lock",      cmd: ["mw-lock"] },
                { icon: "󰐥", label: "Power",     cmd: ["mw-menu", "toggle", "system"] }
            ]

            delegate: Rectangle {
                id: tile
                required property var modelData

                readonly property bool isToggle: modelData.state !== undefined
                readonly property bool on: isToggle && (Toggles[modelData.state] ?? false)

                Layout.fillWidth: true
                implicitHeight: 58
                radius: Config.radius
                color: tile.on ? Theme.accent
                     : area.containsMouse ? Theme.overlay
                     : Theme.surface

                Behavior on color { ColorAnimation { duration: 110 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: tile.modelData.icon
                        color: tile.on ? Theme.bg : Theme.accentAlt
                        font.family: Config.font
                        font.pixelSize: 18
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: tile.modelData.label
                        color: tile.on ? Theme.bg : Theme.fg
                        font.family: Config.font
                        font.pixelSize: Config.fontSize - 3
                    }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        Hypr.exec(tile.modelData.cmd);
                        if (tile.isToggle || tile.modelData.keepOpen) Toggles.refreshSoon();
                        else SidebarState.hide();
                    }
                }
            }
        }
    }
}
