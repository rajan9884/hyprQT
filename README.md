# hyprQT

Hyprland + Quickshell desktop for Arch. Lua-scripted Hyprland, a Quickshell
bar/panels, and a wallpaper→palette theme engine. The repo is the only copy
of every config file — `install.sh` symlinks `config/` into `~/.config`, so
editing either path edits the same file.

## What's inside

| Component | Detail |
|---|---|
| `config/hypr/` | Hyprland config as Lua (`hyprland.lua`, `keybinds.lua`, `look.lua`, `rules.lua`, `monitors.lua`) — loaded via Hyprland's Lua parser; plus `hyprlock.conf`, `hypridle.conf`, helper `scripts/` and `bin/` helpers (linked to `~/.local/bin`) |
| `config/quickshell/` | Bar, launcher, panels, OSDs, notifications, clipboard/webapps plugins |
| `config/theme/` | Theme engine: `bin/theme.py`, 20+ presets in `themes/`, `targets.toml` mapping Matugen/percent-encoded palettes to foot/cava/rofi/starship/GTK/helium/hyprlock outputs; `bin/foot-live.py` hot-reload |
| `config/foot/` | Terminal (font, scrollback, key-bindings); colors are theme-generated |
| `config/shell/` | `.zshrc`, `.zprofile`, `.bashrc`, `.gitconfig` + `shell/git-accounts.sh`; `.zprofile` execs `~/.local/bin/start-hyprland` on tty1 |
| `config/Thunar/` | File manager; `uca.xml` (foot "Open Terminal Here", bat "Preview" action), `accels.scm` (Space → preview; locked read-only) |
| `config/{rofi,cava,fastfetch,matugen,gtk-3.0,gtk-4.0}` + `chromium-flags.conf` | Small per-app configs |
| `packages.txt` | Full package list (official-repo names, AUR handled automatically) |
| `install.sh` / `update.sh` | See below |
| `wallhaven-k8jvm7.jpg` | Seed wallpaper |

## Install (new system)

```sh
git clone <your-fork> ~/hyprQT
cd ~/hyprQT
./install.sh
```

`install.sh` verifies you're on an Arch-based distro, bootstraps `yay` if no
AUR helper exists, installs `packages.txt`, sets zsh default, symlinks
`config/` → `~/.config` (real files in the way are backed up to
`~/.config-backups/`), locks the Thunar accel map, starts PipeWire, and
applies the default wallpaper/theme. Log out, then log in on tty1 (`.zprofile`
starts Hyprland automatically).

## Update (existing system)

```sh
./update.sh              # new packages + new files + theme regen
./update.sh --dry-run    # preview
```

## Theme

```sh
theme apply | wallpaper <img> | next | list | new <name> [source]
```

Palette → foot/cava/rofi/starship/GTK/hyprlock/webapp-theme via
`config/theme/targets.toml`; consumers reload live. Matugen drives
wallpaper-derived colors, `packages.txt` installs it.

## Keybinds worth knowing

`SUPER+C/V/X/A` universal clipboard (auto-detects terminal vs. app),
`SUPER+ Space` Thunar read-only preview (`q` closes), `SUPER+CTRL+T` btop,
Super+Return terminal. See `config/hypr/keybinds.lua` and the Cheatsheet
(`SUPER+?`) for the full list.
