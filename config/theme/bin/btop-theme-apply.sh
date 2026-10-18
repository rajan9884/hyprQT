#!/bin/bash
# Update the color_theme line in btop.conf to use the generated theme
CONF_FILE="$HOME/.config/btop/btop.conf"
if [ -f "$CONF_FILE" ]; then
    sed -i 's/^color_theme = .*/color_theme = "current"/' "$CONF_FILE"
    # Optionally, try to signal btop to reload config? We don't know how.
    # We can try to send SIGHUP and see if it works? Let's not for now.
    # If we want to restart btop, we can do:
    # pkill btop && btop &   # but this might be too aggressive and we don't know if the user wants it.
    # We'll just update the config and let the user restart btop manually if needed.
    echo "Updated btop.conf to use theme 'current'"
else
    echo "btop.conf not found at $CONF_FILE"
fi
