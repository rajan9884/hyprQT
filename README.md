# hyprQT

Hyprland + Quickshell desktop setup. The repo is the only copy of each
config file — `install.sh` symlinks everything into `~/.config`, so editing
either path edits the same file.

## Layout

- `config/` — all configuration (hypr, quickshell, foot, rofi, theme, ...)
- `install.sh` — full install: packages, symlinks, theme, services
- `update.sh` — incremental update: new packages, new symlinks, theme regen
- `packages.txt` — package list consumed by both scripts
- `wallhaven-k8jvm7.jpg` — default wallpaper seed

## Usage

```sh
./install.sh                    # fresh install (backs up existing files)
./update.sh                     # pick up new files + packages + theme
./update.sh --dry-run           # preview what update.sh would do
./update.sh --restart-shell     # also restart quickshell after updating
```

Theme: `theme apply | wallpaper <img> | next | list` (via `~/.config/theme`).

## Author

Rajan — https://github.com/rajan9884 — rajan.dev.jaiswal@gmail.com
