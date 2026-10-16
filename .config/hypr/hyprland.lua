-- ~/.config/hypr/hyprland.lua
-- Docs: https://wiki.hypr.land/Configuring/Start/

---- MY PROGRAMS ----

mainMod    = "SUPER"
terminal   = "foot"
fileManager = "thunar"
browser    = "brave"

---- AUTOSTART ----

local home = os.getenv("HOME")

hl.on("hyprland.start", function()
    -- hl.exec_cmd("dunst") replaced with quickshell 
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd(home .. "/.config/hypr/scripts/portal-warmup.sh")
    hl.exec_cmd(home .. "/.local/bin/power-profiles watch")
    hl.exec_cmd("thunar --daemon 2>/dev/null &")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("sh -c 'B=$(cat \"${XDG_STATE_HOME:-$HOME/.local/state}/backlight\" 2>/dev/null); case \"$B\" in \"\"|*[!0-9]*) ;; *) brightnessctl -c backlight set \"$B\" >/dev/null 2>&1 || true;; esac'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true")

    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper-restore.sh")
    hl.exec_cmd("sleep 2 && QSG_RENDER_LOOP=basic qs -n") -- -n: never start a 2nd bar
end)

---- ENVIRONMENT VARIABLES ----

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")

---- INPUT ----

hl.config({
    input = {
        kb_layout = "us",
        -- Snappy repeat from old-arch (Hyprland defaults 600ms/25 feel laggy).
        repeat_rate = 40,
        repeat_delay = 250,
        follow_mouse = 1,
        sensitivity = 0.5,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },
})

-- LAYOUT
hl.config({
    dwindle = { preserve_split = true },
})
hl.config({
    master = { new_status = "master" },
})

-- MISC
hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})

---- SPLIT-OUT FILES ----

require("monitors")
require("keybinds")
require("look")
require("rules")
