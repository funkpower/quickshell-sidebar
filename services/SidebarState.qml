pragma Singleton

import Quickshell

// Just whether the sidebar is open. Same reason as Notifs: the cards need to
// close it after acting, and reaching back into modules/ from
// modules/sidebar/ would make the two import each other.
Singleton {
    property bool shown: false
    function toggle() { shown = !shown; }
    function show()   { shown = true; }
    function hide()   { shown = false; }
}
