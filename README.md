# quickshell-sidebar

A slide-in control centre for Hyprland, built with [Quickshell](https://quickshell.org),
plus the menu overlay, launcher, lock screen and notification daemon its tiles drive.

Press **Super+A** and a panel slides in from the right edge of the focused monitor:

- **Quick settings**: a grid of tiles. Toggles (night light, idle lock, HDR, mute)
  fill with the accent colour while they're on, and read their state back from the
  same command a keybinding would run, so the tile and the CLI never disagree.
  Actions (audio devices, Bluetooth, clipboard, wallpaper, theme, windows, display,
  capture, apps, lock, power) do the thing and get out of the way.
- **Media**: now playing, with transport controls, for any MPRIS player.
- **Weather**: current conditions and the next four days from Open-Meteo. No API key.
- **Notifications**: history, with clear-all.

The lock screen shows the clock over weather, the liturgical day and a calendar.
The church widget comes from [typikon](https://git.pumpin.online/funkpower/typikon):
today's feast, season, rank and fast, and the week ahead, for twenty Orthodox
jurisdictions and four Byzantine Catholic churches.

Click anywhere else, or press Super+A again, and it slides back out.

## How it fits together

Everything the UI does is a plain `mw-*` command, and every `mw-*` command
reaches the shell through Quickshell's IPC:

```
Super+A ──► mw-sidebar ──► qs -c mw ipc call sidebar toggle ──► Sidebar.qml
tile    ──► mw-nightlight toggle / mw-menu toggle capture / …
```

So anything you can click, you can also script:

```sh
mw-sidebar                          # toggle the sidebar
mw-menu toggle system               # open a menu
mw-menu routes                      # list every menu
printf 'a\tApple\nb\tBanana\n' | mw-menu pick Fruit    # blocking picker, prints the choice
mw-weather --text
qs -c mw ipc show                   # every IPC target and function
```

| Path | What it is |
|---|---|
| `shell.qml` | Entry point |
| `Config.qml` | Every tunable: font, radius, clock formats, idle timers, lock screen widgets |
| `Ipc.qml` | The IPC surface the `mw-*` commands call |
| `modules/Sidebar.qml` | The panel itself: a layer-shell window anchored top, bottom and right |
| `modules/sidebar/` | One file per card. Adding a card is a file here and a line in `Sidebar.qml` |
| `modules/Overlay.qml` | Menus, app launcher, and the blocking pickers `mw-menu` exposes |
| `services/Routes.qml` | The menu tree. Every entry is an argv, so adding one is one line |
| `modules/Lock.qml` | `WlSessionLock` lock screen, PAM-backed |
| `modules/Idle.qml` | Idle lock and monitor blanking, in-process |
| `modules/Notifications.qml` | Notification daemon |
| `modules/Osd.qml` | Volume and brightness OSD |
| `modules/Background.qml` | Wallpaper |
| `bin/` | The `mw-*` commands |
| `themes/` | Colour schemes. The shell reads `~/.config/mw-theme/colors.json` |

## Requirements

- **Hyprland 0.56 or later with the Lua config.** The scripts dispatch with
  `hyprctl dispatch "hl.dsp.…"`, which the older hyprlang parser doesn't accept.
- **Quickshell 0.3** or later
- A **Nerd Font**. JetBrainsMono Nerd Font by default; change it in `Config.qml`.
- `jq`, `python3`, `curl`, `libnotify` (`notify-send`)

For the tiles and menus, install what you use:

| Feature | Needs |
|---|---|
| Volume, mute, audio devices | `pamixer`, `pactl` (PipeWire or PulseAudio) |
| Night light | `hyprsunset` |
| Clipboard history | `cliphist`, `wl-clipboard` |
| Capture | `grim`, `slurp`, `satty`, `hyprpicker`, `gpu-screen-recorder`, `tesseract` (OCR) |
| Church widget | [`typikon`](https://git.pumpin.online/funkpower/typikon): `cargo install --git https://git.pumpin.online/funkpower/typikon` |
| Monitor brightness | `ddcutil`, the `i2c-dev` module, and membership of the `i2c` group |
| Bluetooth, mixer, Wi-Fi tiles | `ghostty` running `bluetui`, `wiremix`, `impala` |

Anything missing just makes its tile do nothing. The rest keep working.

## Install

```sh
git clone https://git.pumpin.online/funkpower/quickshell-sidebar ~/.config/quickshell/mw

# The commands on PATH
mkdir -p ~/.local/bin
ln -s ~/.config/quickshell/mw/bin/mw-* ~/.local/bin/

# A theme
ln -sfn ~/.config/quickshell/mw/themes/gruvbox ~/.config/mw-theme
```

It has to live at `~/.config/quickshell/mw`, because the commands address it as `qs -c mw`.

Only one notification daemon can run at a time, so stop mako, dunst or swaync first.
Then start the shell and bind the key. In `hyprland.lua`:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c mw")
    hl.exec_cmd("wl-paste --watch cliphist store")   -- clipboard history
end)

hl.bind("SUPER + A", hl.dsp.exec_cmd("mw-sidebar"))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("mw-menu toggle apps"))
```

Wallpapers are read from `~/Pictures/Wallpapers` (or `Wallpaper`), or from
`$MW_WALLPAPER_DIR`. Weather finds your location by IP. If that guesses wrong,
which it often does on a VPN, set it yourself:

```sh
mw-weather --set-location "Chicago, Illinois"
```

## Customising

- **Tiles**: edit the model in `modules/sidebar/TogglesCard.qml`. A tile with a
  `state:` field is a toggle and reads that property from `services/Toggles.qml`;
  one without it is an action.
- **Menus**: `services/Routes.qml`.
- **Colours**: copy a directory under `themes/`, edit its `colors.json`, then run
  `mw-theme set <name>`.
- **HDR**: the HDR tile acts on the focused monitor. Set `MW_HDR_OUTPUT=DP-1`
  (for example) to pin it to one output.
- **Units**: `MW_WEATHER_UNITS=celsius` and `MW_WEATHER_WIND=kmh`.
- **Church calendar**: set `churchJurisdiction` in `Config.qml` (see `typikon --list`),
  or leave it empty and run `typikon --set-default <jurisdiction>`.
  `churchTypikonFast` shows the Typikon's full fasting discipline.
- **Lock and unlock hooks**: `lockHooks` and `unlockHooks` in `Config.qml`, each a
  list of commands run in order, such as `["playerctl", "pause"]` on lock.
- **Idle timers and lock screen widgets**: `Config.qml`.

## License

MIT. See [LICENSE](LICENSE).
