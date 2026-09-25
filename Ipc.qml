import Quickshell
import Quickshell.Io
import qs.modules
import qs.services

// The shell's CLI surface. Everything the UI can do is reachable as
//   qs -c mw ipc call <target> <function> [args]
// which is what the mw-* commands drive, and what lets a script operate the
// desktop without synthesising input.
//
// Blocking calls (pick, input) take a FIFO path: the shell writes the result
// there and the caller reads it, because an IPC function cannot itself wait
// for a human.
Scope {
    IpcHandler {
        target: "shell"
        function ping(): string { return "ok"; }
        function status(): string {
            return JSON.stringify({
                theme: Theme.name,
                overlay: { shown: Overlay.shown, mode: Overlay.mode, route: Overlay.route,
                           entries: Overlay.entries.length, filtered: Overlay.filtered.length },
                idle: Idle.enabled,
                locked: Lock.locked
            });
        }
    }

    IpcHandler {
        target: "menu"
        function toggle(route: string): void { Overlay.toggle(route === "" ? "root" : route); }
        function open(route: string): void {
            if (route === "apps") Overlay.openApps(); else Overlay.openRoute(route === "" ? "root" : route);
        }
        function close(): void { Overlay.close(); }
        function routes(): string { return Routes.names().join("\n"); }
    }

    IpcHandler {
        target: "picker"
        function pick(title: string, items: string, fifo: string): void { Overlay.openPick(title, items, fifo); }
        function input(title: string, fifo: string): void { Overlay.openInput(title, fifo); }
        function show(title: string, body: string): void { Overlay.openShow(title, body); }
    }


    IpcHandler {
        target: "sidebar"
        function toggle(): void { SidebarState.toggle(); }
        function open(): void { SidebarState.show(); }
        function close(): void { SidebarState.hide(); }
        function shown(): string { return SidebarState.shown ? "true" : "false"; }
    }


    IpcHandler {
        target: "osd"
        function audio(): void { Osd.showAudio(); }
        function brightness(): void { Osd.showBrightness(); }
    }

    IpcHandler {
        target: "idle"
        function on(): void { Idle.enabled = true; }
        function off(): void { Idle.enabled = false; }
        function toggle(): void { Idle.enabled = !Idle.enabled; }
        function enabled(): string { return Idle.enabled ? "true" : "false"; }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { Lock.lock(); }
        function locked(): string { return Lock.locked ? "true" : "false"; }
    }

    IpcHandler {
        target: "theme"
        function reload(): void { Theme.reload(); }
        function name(): string { return Theme.name; }
    }


    IpcHandler {
        target: "background"
        function reload(): void { Background.reload(); }
    }

    IpcHandler {
        target: "notifications"
        function dismissAll(): void { Notifications.dismissAll(); }
        function clearHistory(): void { Notifs.clearHistory(); }
        function count(): string { return String(Notifs.active.length); }
        // Whether a repeat is one application sending twice or the shell
        // showing one notification twice is not answerable from the screen —
        // both look identical. The ids here settle it.
        function recent(): string {
            return JSON.stringify(Notifs.history.slice(0, 15).map(h => ({
                id: h.id, app: h.appName, summary: h.summary,
                time: h.time instanceof Date ? h.time.toISOString() : String(h.time)
            })));
        }
    }
}
