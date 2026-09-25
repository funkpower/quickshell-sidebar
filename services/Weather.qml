pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs

// All the work happens in mw-weather, which caches for 15 minutes — the bar
// and the sidebar both read the same fetch rather than each hitting the
// network. This just re-reads it on a timer.
Singleton {
    id: root

    property bool   available: false
    property string location: ""
    property int    temp: 0
    property int    feelsLike: 0
    property int    humidity: 0
    property int    wind: 0
    property string label: ""
    property string icon: "󰖙"
    property bool   isDay: true
    property var    days: []

    function refresh() { if (!proc.running) proc.running = true; }

    Process {
        id: proc
        command: ["mw-weather", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text);
                    root.available = d.available ?? false;
                    if (!root.available) return;
                    root.location  = d.location  ?? "";
                    root.temp      = d.temp      ?? 0;
                    root.feelsLike = d.feelsLike ?? 0;
                    root.humidity  = d.humidity  ?? 0;
                    root.wind      = d.wind      ?? 0;
                    root.label     = d.label     ?? "";
                    root.icon      = d.icon      ?? "󰖙";
                    root.isDay     = d.isDay     ?? true;
                    root.days      = d.days      ?? [];
                } catch (e) {
                    root.available = false;
                }
            }
        }
    }

    Timer {
        interval: 600000          // 10 min; mw-weather's own cache is 15
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
