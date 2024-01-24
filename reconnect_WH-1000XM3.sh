#!/bin/bash

# Script to disconnect and reconnect Sony's WH-1000XM3

# This script needs following packages to work
# pulseaudio-utils (for pacmd. it is used to set a2dp_sink profile on headset.)
# bluez (for bluetoothctl. it is used disconnect and connect the headset.)
# libnotify-bin (for notify-send. it is used to send toast notifications from CLI.)
# humanity-icon-theme (for bluetooth icon)

device_name='WH-1000XM3'
bt_icon='/usr/share/icons/Humanity/apps/48/bluetooth.svg'
bt_ctl=$(command -v bluetoothctl)
pa_cmd=$(command -v pacmd)
bt_mac=$(${bt_ctl} devices | grep ${device_name} | cut -f 2 -d ' ')
pulseaudio_card=$(${pa_cmd} list-cards | grep --before-context 4 "${device_name}" | grep name | cut -f 2 -d ' ' | tr -d '<>')


$bt_ctl disconnect $bt_mac |  tr '\n' '\0' | xargs -0 -n1 --max-chars 1000 /usr/bin/notify-send --icon=${bt_icon} "Disconnecting ${device_name}"
$bt_ctl connect $bt_mac  | tr '\n' '\0' | xargs -0 -n1 --max-chars 1000 /usr/bin/notify-send --icon=${bt_icon} "Connecting ${device_name}"

# set profile in pulseaudio
${pa_cmd} set-card-profile "${pulseaudio_card}" a2dp_sink
if [ "$?" -gt 0 ]; then
    /usr/bin/notify-send --icon=${bt_icon} "${device_name}" "Could not set profile to a2dp_sink."
fi
