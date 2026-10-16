#!/usr/bin/env bash
# Circular transition (growing circle from screen center) for consistency.
# Other options: fade, wipe, grow, outer, wave, center, any, random

img="$1"
[[ -f "$img" ]] || { echo "commands.sh: not a file: $img" >&2; exit 1; }

awww img "$img" -t center --transition-duration 1

mkdir -p "$HOME/.cache/43pr"
setsid -f python3 "$HOME/.config/43pr/bin/theme.py" wallpaper "$img" \
    >>"$HOME/.cache/43pr/theme.log" 2>&1
