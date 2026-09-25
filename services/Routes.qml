pragma Singleton

import Quickshell

// The menu is a thin shell over the mw-* commands — every entry is literally an
// argv. Nothing here does work of its own, which is why `mw-menu routes` can
// enumerate the whole UI for a script and why adding an entry is one line.
Singleton {
    readonly property var routes: ({
        "root": {
            title: "Menu",
            items: [
                { icon: "󱓞", label: "Apps",            route: "apps" },
                { icon: "󰍉", label: "Find a window",  exec: ["mw-windows"] },
                { icon: "󰸉", label: "Theme",           route: "theme" },
                { icon: "󰄀", label: "Capture",         route: "capture" },
                { icon: "󰕾", label: "Audio",           route: "audio" },
                { icon: "󰍹", label: "Display",         route: "display" },
                { icon: "󰖯", label: "Windows",         route: "windows" },
                { icon: "󰐥", label: "System",          route: "system" }
            ]
        },

        "system": {
            title: "System",
            items: [
                { icon: "󰌾", label: "Lock",      exec: ["mw-session", "lock"] },
                { icon: "󰤄", label: "Suspend",   exec: ["mw-session", "suspend"] },
                { icon: "󰋊", label: "Hibernate", exec: ["mw-session", "hibernate"] },
                { icon: "󰜉", label: "Reboot",    exec: ["mw-session", "reboot"] },
                { icon: "󰐥", label: "Power off", exec: ["mw-session", "poweroff"] },
                { icon: "󰍃", label: "Log out",   exec: ["mw-session", "logout"] }
            ]
        },

        "theme": {
            title: "Theme",
            items: [
                { icon: "󰸉", label: "Gruvbox",    exec: ["mw-theme", "set", "gruvbox"] },
                { icon: "󰸉", label: "Gruvbox Green", exec: ["mw-theme", "set", "gruvbox-green"] },
                { icon: "󰸉", label: "Everforest", exec: ["mw-theme", "set", "everforest"] },
                { icon: "󰸉", label: "Cachy",      exec: ["mw-theme", "set", "cachy"] },
                { icon: "󰋩", label: "Next wallpaper", exec: ["mw-background", "next"] }
            ]
        },

        "capture": {
            title: "Capture",
            items: [
                { icon: "󰆞", label: "Region",        exec: ["mw-capture", "region"] },
                { icon: "󰍹", label: "Screen",        exec: ["mw-capture", "screen"] },
                { icon: "󰖯", label: "Window",        exec: ["mw-capture", "window"] },
                { icon: "󰕧", label: "Record",        exec: ["mw-capture", "record"] },
                { icon: "󰈊", label: "Extract text",  exec: ["mw-capture", "text"] },
                { icon: "󰈋", label: "Pick a colour", exec: ["mw-capture", "colour"] }
            ]
        },

        "audio": {
            title: "Audio",
            items: [
                { icon: "󰓃", label: "Next output", exec: ["mw-audio", "output", "next"] },
                { icon: "󰝟", label: "Mute",        exec: ["mw-audio", "mute"] },
                { icon: "󰍬", label: "Mute mic",    exec: ["mw-audio", "mic-mute"] },
                { icon: "󰋋", label: "Mixer",       exec: ["ghostty", "-e", "wiremix"] }
            ]
        },


        "windows": {
            title: "Windows",
            items: [
                { icon: "󰖯", label: "Pop window out",       exec: ["mw-window", "pop"] },
                { icon: "󰊓", label: "Toggle gaps",          exec: ["mw-window", "gaps"] },
                { icon: "󰆾", label: "Centre window",        exec: ["mw-window", "center"] },
                { icon: "󰘸", label: "Send behind (floating only)", exec: ["mw-window", "back"] },
                { icon: "󰸉", label: "Toggle see-through",  exec: ["mw-window", "see-through"] },
                { icon: "󰘷", label: "Bring to front",       exec: ["mw-window", "front"] }
            ]
        },

        "display": {
            title: "Display",
            items: [
                { icon: "󰍹", label: "Monitors",         exec: ["mw-monitor", "list"] },
                { icon: "󰖙", label: "Toggle HDR",       exec: ["mw-monitor", "hdr", "toggle"] },
                { icon: "󰌵", label: "Toggle nightlight",exec: ["mw-nightlight", "toggle"] },
                { icon: "󰅶", label: "Toggle idle lock", exec: ["mw-idle", "toggle"] }
            ]
        },

        "network": {
            title: "Network",
            items: [
                { icon: "󰤨", label: "Wi-Fi",     exec: ["ghostty", "-e", "impala"] },
                { icon: "󰂯", label: "Bluetooth", exec: ["ghostty", "-e", "bluetui"] }
            ]
        }
    })

    function names() {
        return Object.keys(routes);
    }
}
