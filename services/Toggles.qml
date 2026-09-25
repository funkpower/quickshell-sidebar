pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live state for the sidebar's toggle tiles.
//
// Each reading comes from the same mw-* command a keybinding would run, so a
// tile and the CLI can never disagree about whether something is on. Before
//
// Polled only while the sidebar is open. It is shut almost all of the time,
// and none of these are worth four subprocesses a second in the background.
Singleton {
    id: root

    // Set by the sidebar while it is on screen.
    property bool watching: false

    property bool nightlight: false
    property bool idleLock: false
    property bool hdr: false
    property bool muted: false
    property bool micMuted: false
    property int  volume: 0

    function refresh() {
        if (!night.running) night.running = true;
        if (!idle.running)  idle.running  = true;
        if (!hdrp.running)  hdrp.running  = true;
        if (!audio.running) audio.running = true;
    }

    // Re-read shortly after a tile is clicked: the command has to actually run
    // and the compositor has to act on it before the new state is readable.
    function refreshSoon() { settle.restart(); }

    Timer {
        id: settle
        interval: 400
        onTriggered: root.refresh()
    }

    Timer {
        running: root.watching
        interval: 4000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: night
        command: ["mw-nightlight", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.nightlight = JSON.parse(this.text).enabled ?? false; } catch (e) {}
            }
        }
    }

    Process {
        id: idle
        command: ["mw-idle", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.idleLock = JSON.parse(this.text).enabled ?? false; } catch (e) {}
            }
        }
    }

    Process {
        id: hdrp
        command: ["mw-monitor", "hdr", "status", "", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.hdr = JSON.parse(this.text).enabled ?? false; } catch (e) {}
            }
        }
    }

    Process {
        id: audio
        command: ["mw-audio", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text);
                    root.muted    = d.muted ?? false;
                    root.micMuted = d.micMuted ?? false;
                    root.volume   = d.volume ?? 0;
                } catch (e) {}
            }
        }
    }
}
