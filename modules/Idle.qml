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

    // The same, on the lock screen, where it has to be dependable. The monitor
    // above honours idle inhibitors, so a browser tab or a call holding one
    // kept a locked desk lit all night; nothing behind a lock is being watched,
    // so this one ignores them.
    IdleMonitor {
        id: lockedBlank
        enabled: Lock.locked
        respectInhibitors: false
        timeout: Config.lockBlankMs / 1000
        onIsIdleChanged: if (isIdle) Hypr.exec(["mw-monitor", "dpms", "off"])
    }

    // An idle monitor fires once per idle period. A panel that wakes on its own
    // — a DisplayPort link retraining, a hotplug — comes back lit with the
    // period still running and nothing left to fire, so while the locked desk
    // is idle the blank is asserted again every minute. Input ends the idle
    // period and with it this timer, so it never fights the compositor waking
    // the screens for a real keypress.
    Timer {
        interval: 60000
        repeat: true
        running: Lock.locked && lockedBlank.isIdle
        onTriggered: Hypr.exec(["mw-monitor", "dpms", "off"])
    }
}
