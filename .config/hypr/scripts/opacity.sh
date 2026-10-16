#!/bin/bash
# Global opacity menu (ported from original dotfiles opacity.sh).
# SUPER+O. Pick a value -> applies everywhere:
#   - first `opacity = ".* override"` window rule in hypr/rules.lua
#   - quickshell Theme.qml bgAlpha
#   - rofi colors.rasi bg alpha (if present; generated file)
# then reloads hypr + restarts quickshell.
# rofi dmenu with the original 420x290 theme (config.rasi).

choice=$(printf "100%%\n90%%\n80%%\n70%%\n60%%\n50%%\n40%%" | rofi -dmenu -p "") || exit 0
[ -z "${choice:-}" ] && exit 0

case "$choice" in
    "100%") opacity=1.0; alpha=FF; pct=100 ;;
    "90%")  opacity=0.9; alpha=E6; pct=90 ;;
    "80%")  opacity=0.8; alpha=CC; pct=80 ;;
    "70%")  opacity=0.7; alpha=B3; pct=70 ;;
    "60%")  opacity=0.6; alpha=99; pct=60 ;;
    "50%")  opacity=0.5; alpha=80; pct=50 ;;
    "40%")  opacity=0.4; alpha=66; pct=40 ;;
    *) exit 0 ;;
esac

sed -i --follow-symlinks "0,/opacity = \".* override\"/s//opacity = \"$opacity override\"/" ~/.config/hypr/rules.lua
if [ -f ~/.config/quickshell/Theme.qml ]; then
    sed -i --follow-symlinks -E "s/(property real bgAlpha: )[0-9.]+/\1$opacity/" ~/.config/quickshell/Theme.qml
fi
if [ -f ~/.config/rofi/colors.rasi ]; then
    sed -i --follow-symlinks -E "s/(bg:[[:space:]]*#[0-9A-Fa-f]{6})([0-9A-Fa-f]{2})?;/\1$alpha;/" ~/.config/rofi/colors.rasi
fi

# Quickshell surfaces with their OWN saved opacity ignore Theme.bgAlpha,
# so SUPER+O must write the state files too (they hot-reload + qs restarts below):
#   bar-state.json        bgOpacity      0-1 float
#   powermenu-state.json  panelOpacity/itemOpacity  0-100 int
#   mediaosd-state.json   bgOpacity      0-100 int
OPACITY="$opacity" PCT="$pct" python3 - <<'EOF'
import json, os
home = os.path.expanduser("~")
opacity = float(os.environ["OPACITY"])
pct = int(os.environ["PCT"])
def upd(rel, fn):
    p = os.path.join(home, rel)
    try:
        with open(p) as f:
            d = json.load(f)
    except (FileNotFoundError, ValueError):
        return
    fn(d)
    with open(p, "w") as f:
        json.dump(d, f, indent=2)
upd(".config/quickshell/state/bar-state.json", lambda d: d.update(bgOpacity=opacity))
upd(".config/quickshell/state/powermenu-state.json",
    lambda d: d.update(panelOpacity=pct, itemOpacity=pct))
upd(".config/quickshell/state/mediaosd-state.json", lambda d: d.update(bgOpacity=pct))
EOF

hyprctl reload

pkill qs 2>/dev/null || true
sleep 0.2
QSG_RENDER_LOOP=basic qs -n >/dev/null 2>&1 &
