#!/bin/sh

export PLASMA_LOG_FILE='/var/log/plasmashell'

# Make an xrandr call as it kind of refreshes what's currently connected.
xrandr --listactivemonitors &> /dev/null

if [ -f "$PLASMA_LOG_FILE" ]; then
   truncate -s 0 $PLASMA_LOG_FILE
else
   /usr/lib/x86_64-linux-gnu/libexec/kf5/kdesu --noignorebutton -c "touch $PLASMA_LOG_FILE"
   /usr/lib/x86_64-linux-gnu/libexec/kf5/kdesu --noignorebutton -c "chown $USER:$USER $PLASMA_LOG_FILE"
fi

if [ "$?" -ne "0" ]; then
    kdialog --sorry "Unable to truncate $PLASMA_LOG_FILE. Please make sure the file exists and you have permissions to write to it."
    exit 1
fi

kill -s TERM $(pgrep plasmashell)
plasmashell &> $PLASMA_LOG_FILE &
