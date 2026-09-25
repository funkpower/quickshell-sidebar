//@ pragma UseQApplication

import Quickshell
import QtQuick
import qs.modules
import qs.services

// Sidebar, menu overlay, launcher, notifications, lock screen, idle locking,
// OSD, wallpaper and the IPC surface the mw-* commands drive.
ShellRoot {
    Ipc {}

    // Singletons are created on first use, so the ones that must be live from
    // startup — rather than waiting for an IPC call — are touched here.
    Scope {
        Component.onCompleted: {
            void Notifications.active;
            void Sidebar.shown;
            void Background.wallpaper;
            void Idle.enabled;
            void Lock.locked;
            void Theme.name;
            void Weather.available;
        }
    }
}
