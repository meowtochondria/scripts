#!/bin/sh -x

test -z "$WEZTERM_CONFIG_FILE" && test -f "$HOME/src/scripts/wezterm.lua" && export WEZTERM_CONFIG_FILE="$HOME/src/scripts/wezterm.lua"

DESKTOP_FILE='/usr/share/applications/org.wezfurlong.wezterm.desktop'
# get binary name by looking at 'Exec' value in .desktop file.
BIN=$(grep -P '^Exec=' $DESKTOP_FILE | cut -f 2 -d '=' | cut -f 1 -d ' ')
BIN_BASENAME=$(basename $BIN)

# wezterm does put its name in window title. so wmctrl is not able to find it.

# check if app is already running by looking for its PID
PID=$(pgrep --full "$BIN")

# launch app if pid does not exist
test -z "$PID" && /usr/bin/gio launch "$DESKTOP_FILE" && exit 0

# control would reach here only if an instance of app is running, which means PID would not be empty.

# if we are on wayland, use kdotool instead.
# wget https://github.com/jinliu/kdotool/releases/download/v0.2.2-pre/kdotool.tar.gz -O /tmp/kdotool.tar
# tar --extract --directory=/tmp --file /tmp/kdotool.tar
# sudo mv /tmp/kdotool /usr/local/bin/kdotool

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    if [ ! -x /usr/local/bin/kdotool ]; then
        /usr/bin/notify-send --app-name $0 --category=error "kdotool is not installed."
    fi
    wayland_window_id=$(/usr/local/bin/kdotool search "$BIN_BASENAME")
    # if wayland window id is empty but $PID is not empty, that means window is not visible.
    # just kill the window and start again.
    test -z "$wayland_window_id" && kill $PID && exit 0
    /usr/local/bin/kdotool windowactivate $wayland_window_id
    exit 0
fi

# X11
# grab hex identity of the window using pid and wmctrl
WINDOW_IDENTITY=$(/usr/bin/wmctrl -lp | grep "$PID" | cut -f 1 -d ' ')
# raise the window using the identity.
/usr/bin/wmctrl -i -a "$WINDOW_IDENTITY"
