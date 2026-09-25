pragma Singleton

import Quickshell

// Everything tunable about the shell in one place, so a change is a one-line
// edit rather than a hunt through the widgets.
Singleton {
    readonly property int    radius:      8
    readonly property string font:        "JetBrainsMono Nerd Font"
    readonly property int    fontSize:    12

    // Clock formats, defined once so the sidebar, the lock screen and
    // notification timestamps cannot drift apart. Qt format strings: h is the
    // hour without a leading zero, AP the AM/PM marker.
    readonly property string timeFormat:     "h:mm AP"
    readonly property string dateTimeFormat: "ddd d MMM  h:mm AP"
    readonly property string dateFormat:     "dddd d MMMM"

    // Which church's reckoning the church widget keeps. Empty follows whatever
    // `typikon --set-default` wrote; `typikon --list` has every jurisdiction.
    readonly property string churchJurisdiction: ""

    // Show the day at the Typikon's full discipline rather than only what your
    // church's particular law requires. Obligations are still reported and
    // still marked: this changes what is *kept*, not what binds.
    readonly property bool churchTypikonFast: false

    readonly property int    idleLockMs:  600000
    // Blanking comes after the lock, not instead of it: the screens go dark a
    // few minutes later so a glance at a locked desk still shows the clock.
    readonly property int    idleBlankMs: 900000

    // Lock screen widgets. Names are the component files in modules/widgets.
    // Whatever is here is legible to anyone standing at the machine while it
    // is locked, so keep it to ambient information.
    readonly property int  widgetWidth:   430
    readonly property var  lockLayout: [
        ["WeatherWidget"], ["ChurchWidget"], ["CalendarWidget"]
    ]

    // How far the lock screen pulls the wallpaper down behind the widgets.
    // 0 leaves the picture exactly as the desktop draws it.
    readonly property real lockDim: 0.4
}
