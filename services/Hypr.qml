pragma Singleton

import Quickshell

// Small helper so widgets never build Process objects of their own. Anything a
// widget "does" ends up as one of the mw-* commands, same as a keybinding.
Singleton {
    id: root

    // execDetached rather than a Process: there is nothing to read back, and
    // the single shared Process this used to keep meant a second click while
    // the first command was still running either overwrote its argv or was
    // dropped. Two toggles in quick succession would silently do one thing.
    function exec(argv) {
        Quickshell.execDetached(argv);
    }

    function dispatchMenu(route) {
        root.exec(["mw-menu", "toggle", route]);
    }
}
