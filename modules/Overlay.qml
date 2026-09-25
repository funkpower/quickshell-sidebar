pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs
import qs.services

// One overlay serves the launcher, the menus, and the blocking pickers and
// prompts that mw-menu exposes to scripts. They are the same widget — a filter
// box over a list — so they are one implementation rather than four.
Singleton {
    id: root

    property bool   shown: false
    property string mode: "menu"        // menu | apps | pick | input | show
    property string title: ""
    property string route: "root"
    property var    entries: []
    property string body: ""
    property string replyTo: ""         // FIFO a blocking caller is waiting on
    property string query: ""

    readonly property var filtered: {
        if (mode === "input" || mode === "show") return [];
        const q = query.trim().toLowerCase();
        if (q === "") return entries;
        return entries.filter(e =>
            ((e.label ?? "") + " " + (e.sublabel ?? "")).toLowerCase().includes(q));
    }

    // ── entry points ──────────────────────────────────────────────────────
    function openRoute(name) {
        const r = Routes.routes[name];
        if (!r) { console.warn("Overlay: no such route", name); return; }
        mode = "menu"; route = name; title = r.title;
        entries = r.items; query = ""; replyTo = ""; shown = true;
    }

    // A desktop-entry icon name, or a window class, to a themed icon file.
    // Classes are not icon names: Dolphin reports org.kde.dolphin and Java apps
    // report install4j-... , so fall back through the obvious narrowings rather
    // than giving up on the first miss.
    function resolveIcon(hint) {
        if (!hint) return "";
        const tries = [hint, hint.toLowerCase()];
        const dot = hint.lastIndexOf(".");
        if (dot > 0) { tries.push(hint.slice(dot + 1)); tries.push(hint.slice(dot + 1).toLowerCase()); }
        const dash = hint.indexOf("-");
        if (dash > 0) tries.push(hint.slice(0, dash).toLowerCase());
        // hasThemeIcon is the only honest test: iconPath hands back an
        // image://icon/<name> url whether or not anything is behind it, so using
        // it to probe means every name "resolves" and misses paint as a blank
        // chip rather than falling back to a glyph.
        for (const name of tries)
            if (Quickshell.hasThemeIcon(name)) return Quickshell.iconPath(name, "");
        return "";
    }

    function openApps() {
        mode = "apps"; title = "Apps"; query = ""; replyTo = "";
        entries = DesktopEntries.applications.values
            .filter(a => !a.noDisplay)
            .map(a => ({ iconSource: root.resolveIcon(a.icon), label: a.name, entry: a }))
            .sort((a, b) => a.label.localeCompare(b.label));
        shown = true;
    }

    // items arrive as "value\tlabel" lines, optionally with a third field naming
    // an icon — a desktop-entry icon name or a window class. Two-field lines still
    // work, so every existing caller is unaffected.
    function openPick(t, itemText, fifo) {
        mode = "pick"; title = t; query = ""; replyTo = fifo;
        entries = itemText.split("\n").filter(l => l.length > 0).map(l => {
            const f = l.split("\t");
            if (f.length < 2) return { label: l, value: l };
            return {
                value: f[0],
                label: f[1],
                iconSource: f.length > 2 ? root.resolveIcon(f[2]) : "",
                sublabel: f.length > 3 ? f[3] : ""
            };
        });
        shown = true;
    }

    function openInput(t, fifo) {
        mode = "input"; title = t; query = ""; replyTo = fifo; entries = []; shown = true;
    }

    function openShow(t, text) {
        mode = "show"; title = t; body = text; entries = []; replyTo = ""; shown = true;
    }

    function toggle(name) {
        if (shown) { close(); return; }
        if (name === "apps") openApps(); else openRoute(name);
    }

    function close() {
        if (replyTo !== "") reply("");      // never leave a caller blocked
        shown = false;
    }

    // ── committing a choice ───────────────────────────────────────────────
    function reply(value) {
        if (replyTo === "") return;
        writer.command = ["sh", "-c", 'printf %s "$1" > "$2"', "sh", value, replyTo];
        writer.running = true;
        replyTo = "";
    }

    function activate(item) {
        if (!item) return;
        if (mode === "pick") { reply(item.value ?? item.label); shown = false; return; }
        shown = false;
        if (item.route) { openRoute(item.route); return; }
        if (item.exec)  { Hypr.exec(item.exec); return; }
        // execute() ignores Terminal=true, so a terminal app like nvim started
        // with nothing to draw in and exited at once. Give it one.
        if (item.entry?.runInTerminal) { Hypr.exec(["ghostty", "-e", ...item.entry.command]); return; }
        if (item.entry) { item.entry.execute(); return; }
    }

    function submitInput() {
        reply(query);
        shown = false;
    }

    Process { id: writer }

    // ── the surface ───────────────────────────────────────────────────────
    LazyLoader {
        activeAsync: root.shown

        PanelWindow {
            id: win
            WlrLayershell.namespace: root.mode === "apps" ? "mw-launcher" : "mw-menu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors { top: true; bottom: true; left: true; right: true }
            color: Qt.alpha(Theme.bgAlt, 0.55)

            HyprlandFocusGrab {
                windows: [win]
                active: root.shown
                onCleared: root.close()
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Rectangle {
                width: 720
                implicitHeight: Math.min(layout.implicitHeight + 32, win.height - 120)
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -80
                radius: Config.radius * 3
                color: Theme.bg
                border.width: 1
                border.color: Theme.accent

                // Swallow clicks so they don't reach the dismiss layer.
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: layout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Text {
                        text: root.title
                        color: Theme.accent
                        font.family: Config.font
                        font.pixelSize: Config.fontSize + 2
                        font.bold: true
                    }

                    TextInput {
                        id: input
                        visible: root.mode !== "show"
                        Layout.fillWidth: true
                        color: Theme.fg
                        font.family: Config.font
                        font.pixelSize: Config.fontSize + 2
                        focus: true
                        text: root.query
                        onTextChanged: root.query = text

                        Text {
                            anchors.fill: parent
                            visible: input.text === ""
                            text: root.mode === "input" ? "Type and press Enter…" : "Filter…"
                            color: Theme.fgDim
                            font: input.font
                        }

                        Keys.onEscapePressed: root.close()
                        Keys.onReturnPressed: root.mode === "input"
                            ? root.submitInput()
                            : root.activate(root.filtered[list.currentIndex])
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onUpPressed: list.decrementCurrentIndex()
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.surface
                        visible: root.mode !== "input"
                    }

                    // Plain text payload — `mw-menu show`.
                    Text {
                        visible: root.mode === "show"
                        Layout.fillWidth: true
                        text: root.body
                        color: Theme.fg
                        font.family: Config.font
                        font.pixelSize: Config.fontSize
                        wrapMode: Text.NoWrap
                    }

                    ListView {
                        id: list
                        visible: root.mode !== "input" && root.mode !== "show"
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(contentHeight, 460)
                        clip: true
                        spacing: 4
                        model: root.filtered
                        currentIndex: 0
                        onModelChanged: currentIndex = 0

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool current: index === list.currentIndex

                            width: list.width
                            implicitHeight: 46
                            radius: height / 2
                            color: current ? Theme.accentAlt : "transparent"

                            Behavior on color { ColorAnimation { duration: 90 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 7
                                anchors.rightMargin: 16
                                spacing: 12

                                // Icon chip. The disc keeps the column reading as one
                                // rhythm whether an entry resolved a real icon, carries
                                // only a glyph, or has neither.
                                Rectangle {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    radius: width / 2
                                    color: row.current ? Qt.alpha(Theme.bg, 0.22) : Theme.surface

                                    IconImage {
                                        id: chip
                                        anchors.centerIn: parent
                                        implicitSize: 22
                                        // Local theme files, a few KB each. Loading them
                                        // asynchronously just means the list paints blank
                                        // chips for a beat every time it opens.
                                        asynchronous: false
                                        visible: (row.modelData.iconSource ?? "") !== ""
                                                 && status !== Image.Error
                                                 && status !== Image.Null
                                        source: row.modelData.iconSource ?? ""
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !chip.visible
                                        text: row.modelData.icon ?? "󰘳"
                                        color: row.current ? Theme.bg : Theme.accentAlt
                                        font.family: Config.font
                                        font.pixelSize: Config.fontSize + 2
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: row.modelData.label ?? ""
                                        color: row.current ? Theme.bg : Theme.fg
                                        elide: Text.ElideRight
                                        font.family: Config.font
                                        font.pixelSize: Config.fontSize + 1
                                        font.bold: row.current
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        visible: (row.modelData.sublabel ?? "") !== ""
                                        text: row.modelData.sublabel ?? ""
                                        color: row.current ? Qt.alpha(Theme.bg, 0.7) : Theme.fgDim
                                        elide: Text.ElideRight
                                        font.family: Config.font
                                        font.pixelSize: Config.fontSize - 1
                                    }
                                }
                                Text {
                                    visible: row.modelData.route !== undefined
                                    text: "›"
                                    color: row.current ? Theme.bg : Theme.fgDim
                                    font.family: Config.font
                                    font.pixelSize: Config.fontSize + 4
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: list.currentIndex = index
                                onClicked: root.activate(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
