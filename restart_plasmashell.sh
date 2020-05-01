#!/bin/bash

LOG_FILE='/var/log/plasmashell'

# Make an xrandr call as it kind of refreshes what's currently connected.
xrandr --listactivemonitors &> /dev/null

[ -f "$LOG_FILE" ] && truncate -s 0 $LOG_FILE

if [ "$?" -ne "0" ]; then
    kdialog --sorry "Unable to truncate $LOG_FILE. Please make sure the file exists and you have permissions to write to it."
    exit 1
fi

kill -s TERM $(pgrep plasmashell)
plasmashell &> $LOG_FILE &
