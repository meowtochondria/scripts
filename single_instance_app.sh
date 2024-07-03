#!/bin/sh

test -z "$WEZTERM_CONFIG_FILE" && test -f /home/dev/src/scripts/wezterm.lua && export WEZTERM_CONFIG_FILE=/home/dev/src/scripts/wezterm.lua

DESKTOP_FILE='/usr/share/applications/org.wezfurlong.wezterm.desktop'
# get binary name by looking at 'Exec' value in .desktop file.
BIN=$(grep -P '^Exec=' $DESKTOP_FILE | cut -f 2 -d '=' |cut -f 1 -d ' ')

# wezterm does put its name in window title. so wmctrl is not able to find it.

# check if app is already running by looking for its PID
PID=$(pgrep "$BIN")

# launch app if pid does not exist
test -z "$PID" && /usr/bin/gio launch "$DESKTOP_FILE" && exit 0

# control would reach here only if an instance of app is running, which means PID would not be empty.

# grab hex identity of the window using pid and wmctrl
WINDOW_IDENTITY=$(/usr/bin/wmctrl -lp | grep "$PID" | cut -f 1 -d ' ')

# raise the window using the identity.
/usr/bin/wmctrl -i -a "$WINDOW_IDENTITY"
