pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

// Wallpaper, drawn on the background layer. Replaces swaybg/hyprpaper; the
// choice itself lives in a state file that mw-background writes.
Singleton {
    id: root
    property string wallpaper: ""

    // One reader shared by every monitor.
    FileView {
        id: state
        path: Quickshell.env("HOME") + "/.local/state/mw/background"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.wallpaper = text().trim()
    }

    function reload() { state.reload(); }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "mw-background"
            WlrLayershell.layer: WlrLayer.Background
            anchors { top: true; bottom: true; left: true; right: true }

            // Cover the whole output, the strip under the bar included.
            // exclusiveZone: 0 only means "claim none of it for myself" — the
            // surface was still being shrunk by the bar's reservation, which
            // left a 42px band of bare colour along the top. Invisible while
            // the bar had a background of its own; obvious once it did not.
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            color: Theme.bg

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: root.wallpaper !== ""
                source: root.wallpaper === "" ? "" : "file://" + root.wallpaper
            }
        }
    }
}
