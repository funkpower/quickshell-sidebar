pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules
import qs.services

// Idle locking, in-process. Replaces hypridle: there is no second daemon to
// keep in sync with the lock screen, because they are the same program.
Singleton {
    id: root
    property bool enabled: true

    IdleMonitor {
        enabled: root.enabled
        timeout: Config.idleLockMs / 1000
        onIsIdleChanged: if (isIdle && root.enabled) Lock.lock()
    }

    // Monitors are the largest idle draw on most desks, and DPMS off cuts the
    // backlight, which is most of it. This is a separate
    // monitor rather than part of the lock so that it still blanks when idle
    // locking is turned off, and so the screens can come back and go dark
    // again without the lock changing state.
    //
    // Nothing turns them back on here: key_press_enables_dpms and
    // mouse_move_enables_dpms are set in the Hyprland config, so the
    // compositor wakes them on input. Doing it from this side as well raced
    // the compositor and flapped.
    IdleMonitor {
        // Deliberately not gated on root.enabled — that switch is for the
        // lock. Someone who does not want their screen locked still wants the
        // monitors to sleep.
        timeout: Config.idleBlankMs / 1000
        onIsIdleChanged: if (isIdle) Hypr.exec(["mw-monitor", "dpms", "off"])
    }
}
