# mybar

A minimal Wayland status bar built with [Quickshell](https://quickshell.outfoxxed.me/) (QML). Designed as a Waybar replacement for Hyprland, with live theme switching driven by [theme-switch](https://github.com/jesusferm/theme-switch).

## Features

- **Workspaces** — 5 persistent Hyprland workspace buttons per screen
- **Clock** — current time and date
- **IP widget** — primary IP address with LAN / WireGuard / WLAN breakdown on hover
- **Memory** — used / total RAM with tooltip
- **Updates** — pending package count (Arch via `checkupdates` + yay/paru AUR; Fedora via `dnf`)
- **Sound** — volume, mic mute, bluetooth status; scroll to change volume
- **Network** — WiFi (SSID + signal) or Ethernet, expands on hover
- **Battery** — capacity + charge/discharge time estimate
- **Power** — left-click for wlogout, right-click to lock with hyprlock
- **Live theming** — colors reload instantly when you switch themes with theme-switch

## Dependencies

| Tool | Purpose |
|------|---------|
| [Quickshell](https://quickshell.outfoxxed.me/) | Shell framework (QML runtime) |
| Hyprland | Window manager (workspace IPC) |
| NetworkManager (`nmcli`) | Network status |
| PipeWire + WirePlumber (`wpctl`, `pactl`) | Audio/bluetooth status |
| `rfkill` | Bluetooth adapter detection |
| `checkupdates` (`pacman-contrib`) | Arch update checking |
| yay or paru | AUR update checking (optional) |
| hyprlock | Lock screen (right-click power button) |
| wlogout | Power menu (left-click power button) |
| FiraCode Nerd Font Mono | Icon glyphs |
| Fira Sans | Label text |

## Installation

```bash
git clone https://github.com/jesusferm/mybar ~/mybar
```

All script paths are resolved relative to the QML files at runtime, so the project works from any directory.

### Theme integration

mybar reads colors from `~/.config/tc99m/current-theme`, the same file written by [theme-switch](https://github.com/jesusferm/theme-switch). Without it the bar still works — it falls back to a purple palette defined in `Theme.qml`.

To use live theming, install theme-switch and configure your themes there. mybar will pick up color changes instantly via file watching.

### Fonts

Install FiraCode Nerd Font Mono and Fira Sans (e.g. from your distro's repos or [nerdfonts.com](https://www.nerdfonts.com)):

```bash
# Arch
sudo pacman -S ttf-fira-sans
yay -S ttf-firacode-nerd
```

## Usage

```bash
# Launch
quickshell -p ~/dev/rice/mybar

# Or use the helper script (kills any running instance first)
bash ~/dev/rice/mybar/launch.sh
```

To autostart with Hyprland, add to `hyprland.conf`:

```
exec-once = bash ~/dev/rice/mybar/launch.sh
```

## Defaults and customization

| Widget | Action | Default |
|--------|--------|---------|
| NetworkWidget | click | `~/.config/tc99m/quick-nm.sh` if present, otherwise `nm-connection-editor` |
| SoundWidget (BT section) | click | `blueman-manager` |
| UpdatesWidget | click | `kitty -- yay` |
| PowerWidget | left-click | `wlogout` (with margin calculated from monitor resolution) |
| PowerWidget | right-click | `hyprlock` |

Change any of these by editing the relevant `Process` command at the bottom of the corresponding widget file.

## File structure

```
mybar/
├── shell.qml              — ShellRoot entry; spawns one Bar per screen
├── Bar.qml                — PanelWindow (top-anchored, 36 px); wires up all widgets
├── Theme.qml              — Live color loader; watches ~/.config/tc99m/current-theme
├── launch.sh              — Helper: kills old instance and relaunches
├── widgets/
│   ├── qmldir             — QML module registry (add new widgets here)
│   ├── Icons.qml          — Nerd Font codepoint constants
│   ├── TooltipContainer.qml
│   ├── Workspaces.qml
│   ├── Clock.qml
│   ├── IpWidget.qml / IpEntry.qml
│   ├── MemoryWidget.qml
│   ├── UpdatesWidget.qml
│   ├── SoundWidget.qml
│   ├── NetworkWidget.qml
│   ├── BatteryWidget.qml
│   └── PowerWidget.qml
└── scripts/               — Shell scripts called by widgets for system data
    ├── network-status.sh
    ├── battery-status.sh
    ├── sound-status.sh
    ├── memory.sh
    ├── check-updates.sh
    ├── localip.sh
    ├── bluetooth-status.sh
    └── vpn-status.sh
```

## Related projects

- [theme-switch](https://github.com/jesusferm/theme-switch) — Quickshell-based fullscreen theme picker that drives mybar's live color reloading
- [quick-nm](https://github.com/jesusferm/quick-nm) — Quickshell NetworkManager frontend
