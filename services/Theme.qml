pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Colours come from the theme directory that ~/.config/mw-theme points at.
// `mw-theme set` repoints that symlink and calls `theme reload` over IPC —
// watchChanges alone will not fire, because the file on disk never changes,
// only the symlink above it.
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/mw-theme/colors.json"

    property var c: ({})

    readonly property string name:      c.name      ?? "unknown"
    readonly property color  bg:        c.bg        ?? "#282828"
    readonly property color  bgAlt:     c.bgAlt     ?? "#1d2021"
    readonly property color  surface:   c.surface   ?? "#3c3836"
    readonly property color  overlay:   c.overlay   ?? "#504945"
    readonly property color  fg:        c.fg        ?? "#ebdbb2"
    readonly property color  fgDim:     c.fgDim     ?? "#a89984"
    readonly property color  accent:    c.accent    ?? "#b8bb26"
    readonly property color  accentAlt: c.accentAlt ?? "#8ec07c"
    readonly property color  red:       c.red       ?? "#fb4934"
    readonly property color  orange:    c.orange    ?? "#fe8019"
    readonly property color  yellow:    c.yellow    ?? "#fabd2f"
    readonly property color  green:     c.green     ?? "#b8bb26"
    readonly property color  cyan:      c.cyan      ?? "#8ec07c"
    readonly property color  blue:      c.blue      ?? "#83a598"
    readonly property color  magenta:   c.magenta   ?? "#d3869b"

    function reload() {
        file.reload();
        load();
    }

    function load() {
        try {
            root.c = JSON.parse(file.text());
        } catch (e) {
            console.warn("Theme: could not parse", root.path, "-", e);
        }
    }

    FileView {
        id: file
        path: root.path
        blockLoading: true
        watchChanges: true
        onFileChanged: root.reload()
        onLoaded: root.load()
    }

    Component.onCompleted: load()
}
