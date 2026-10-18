# hyprQT

A Lua-scripted Hyprland + Quickshell desktop for Arch Linux. Hyprland reads
its config from Lua (`hl.bind`, `hl.dsp`, `hl.on`), Quickshell renders the
bar/panels/OSDs, and one theme engine pushes a single palette into every app.
Every config file lives in this repo once — `install.sh` symlinks `config/`
into `~/.config`, so editing either path edits the same file.

## Highlights

- **Hyprland in Lua** — keybinds, rules, and look live in `keybinds.lua`,
  `rules.lua`, `look.lua`, `monitors.lua` instead of a flat `hyprland.conf`.
- **One shell, one bar** — Quickshell (`qs`) provides the bar (system tray,
  caffeine/idle toggle, battery → power profiles), a fuzzy launcher with
  inline `=expr` calc, network/bluetooth/audio/display panels, a tabbed
  settings center (audio/display/network/power), notifications, OSDs
  (volume/brightness), power menu, QT opacity menu, to-do, wheel launcher,
  and an in-app cheatsheet (`SUPER+K`). No rofi — every former rofi menu
  is now QT.
- **Palette everywhere** — Matugen derives colors from the wallpaper;
  `theme.py` renders `targets.toml` targets for foot, cava, starship,
  GTK 3/4, hyprlock, and the helium web-app theme, then reloads consumers
  live.
- **Universal clipboard keys** — `SUPER+C/V/X/A` detect a terminal (foot)
  via its window class and translate to Ctrl+Insert / Shift+Insert chords,
  or straight Ctrl+C/V/X/A elsewhere.
- **Scratchpads & web apps** — special workspaces for music/terminal;
  Chromium PWAs installed as app entries through `hypr/bin/webapp-*`.

## Repository layout

```
config/
  hypr/           Hyprland Lua config, hyprlock/hypridle, scripts/, bin/
                  (bin/ helpers are also linked into ~/.local/bin)
  quickshell/     shell.qml + Bar/panels/OSDs/Settings/OpacityMenu; imgs/;
                  scripts/ (opacity-apply); plugins/ (clipboard, webapps);
                  hyprquickpaper (wallpaper picker)
  theme/          bin/theme.py, targets.toml, bin/foot-live.py, themes/*.toml
  foot/           foot.ini  (colors.ini is theme-generated)
  shell/          git-accounts.sh
  Thunar/         uca.xml (foot terminal + bat preview actions),
                  accels.scm (Space → preview; chmod 444 after install)
  cava/           config + shaders + themes
  fastfetch/      config.jsonc
  matugen/        config.toml + semantic.json template
  gtk-3.0/ gtk-4.0/   gtk.css; settings.ini is theme-managed
  .zshrc .zprofile .bashrc .gitconfig   linked into $HOME
  chromium-flags.conf
install.sh        first-run setup (packages, symlinks, theme)
update.sh         incremental: new packages, new links, theme re-render
packages.txt      all packages (official + AUR, split automatically)
wallhaven-k8jvm7.jpg  seed wallpaper
```

## Requirements

- Arch-based Linux with Hyprland, Hyprlock, Hypridle, Quickshell, foot,
  Matugen, PipeWire, NetworkManager, bluez, tmux, and Python 3. Packages on
  the AUR are auto-built by the detected helper (`paru`/`yay`, bootstrapped
  if absent).

## Getting started

```sh
git clone https://github.com/rajan9884/hyprQT.git ~/hyprQT
cd ~/hyprQT
./install.sh
```

`install.sh` verifies you're on an Arch-based system, installs
`packages.txt`, sets zsh default, symlinks `config/` → `~/.config` (real
files in the way are backed up to `~/.config-backups/`), links `hypr/bin/*`
into `~/.local/bin`, locks the Thunar accel map, enables PipeWire, and
applies the seed wallpaper/theme. Log out — `.zprofile` execs
`~/.local/bin/start-hyprland` on tty1 login and the session starts.

## Updating

```sh
./update.sh                 # new packages + links + theme re-render
./update.sh --dry-run       # preview without changes
./update.sh --skip-packages
./update.sh --skip-theme
./update.sh --restart-shell # pkill+restart quickshell
```

## Theme engine

`config/theme/bin/theme.py` CLI:
`wallpaper <img>` · `preset <name>` · `auto` · `apply` · `mode dark|light` ·
`toggle` · `colorgen on|off` · `list` · `new <name> [source]` · `status`.

Matugen extracts a scheme from the wallpaper or one of the `themes/*.toml`
presets; `targets.toml` maps the resulting palette to files under
`~/.config` plus optional reload hooks (foot, cava, GSettings, Hyprland
borders). Presets with `override = true` survive wallpaper changes.

| Action | Bind |
|---|---|
| Light / dark toggle | `SUPER+L` |
| Wallpaper picker | `SUPER+CTRL+Space` |
| Theme carousel | `SUPER+CTRL+SHIFT+Space` |
| Random wallpaper | `SUPER+R` |

## Key bindings

`mainMod = SUPER` (`hyprland.lua`). Cheatsheet overlay inside the shell:
`SUPER+K` or `SUPER+/`. Highlights:

| Keys | Action |
|---|---|
| `SUPER+Return` | Terminal (cwd-aware, foot) |
| `SUPER+SHIFT+B` / `SUPER+SHIFT+ALT+B` | Browser / browser incognito |
| `SUPER+D` / `SUPER+Space` | Quickshell app launcher |
| `ALT+S` | Wheel launcher (Quickshell) |
| `SUPER+SHIFT+N` | nvim |
| `SUPER+E` / `SUPER+SHIFT+F` | Thunar (cwd) |
| `SUPER+W` | Close window |
| `SUPER+F` / `SUPER+ALT+F` | Fullscreen / maximize |
| `SUPER+O` | Opacity menu (100…40%) |
| `SUPER+L` | Light/dark theme toggle |
| `SUPER+S` | Scratchpad; `+CTRL` / `+ALT` send, `+ALT+SHIFT` bring back |
| `SUPER+CTRL+Return` / `SUPER+CTRL+SHIFT+Return` | Terminal scratchpad toggle / send |
| `SUPER+ALT+M` / `SUPER+CTRL+ALT+M` | Music scratchpad toggle / send |
| `SUPER+TAB` / `+SHIFT` / `+CTRL` | Workspace cycle next/prev/origin |
| `SUPER+G`, `SUPER+ALT+G`, `SUPER+ALT+<dirs>` | Window groups |
| `SUPER+P`, `SUPER+ALT+J` | Pseudo-tiling / toggle split |
| `SUPER+CTRL+T` / `SUPER+CTRL+W` | btop / network panel |
| `SUPER+CTRL+Q` | Launcher calc mode (`=expr`, Enter copies) |
| `SUPER+CTRL+I` | Idle lock toggle (bar caffeine icon mirrors it) |
| `SUPER+CTRL+N` / `B` / `A` / `D` | Network / Bluetooth / Audio / Display panel |
| `SUPER+N`, `SUPER+<comma>` variants | Notification center / dismiss / DND |
| `SUPER+C`,`V`,`X`,`A` | Universal clipboard (terminal auto-detect) |
| `SUPER+ALT+T` | To-do list |
| `SUPER+CTRL+Space` / `+SHIFT` | Wallpaper picker / theme carousel |
| `Print`, `SUPER+SHIFT+Print`, `SUPER+SHIFT+S` | Region / full-screen / shot+annotate |
| `SUPER+R` / `SUPER+ALT+R` | Random wallpaper / region recorder |
| `XF86` keys | Volume, brightness, media, touchpad, HDR |

Mouse: `SUPER+drag` move, `SUPER+right-click` resize,
`SUPER+scroll` switch workspace.

## Thunar

Foot's "Open Terminal Here" and a bat-based "Preview (Read-Only)" (Space
opens, `q` closes) come from `config/Thunar/uca.xml` + `accels.scm`
(space bound at uca-action), locked to 444 so GTK doesn't revert the
binding — both files link back to the repo.
