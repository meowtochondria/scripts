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

# if we are on wayland, use kdotool instead.
# wget https://github.com/jinliu/kdotool/releases/download/v0.2.2-pre/kdotool.tar.gz -O /tmp/kdotool.tar
# tar --extract --directory=/tmp --file /tmp/kdotool.tar
# sudo mv /tmp/kdotool /usr/local/bin/kdotool

pgrep Xwayland > /dev/null && test -x /usr/local/bin/kdotool && /usr/local/bin/kdotool windowactivate $(/usr/local/bin/kdotool search "$BIN") && exit 0

# X11
# grab hex identity of the window using pid and wmctrl
WINDOW_IDENTITY=$(/usr/bin/wmctrl -lp | grep "$PID" | cut -f 1 -d ' ')
# raise the window using the identity.
/usr/bin/wmctrl -i -a "$WINDOW_IDENTITY"
