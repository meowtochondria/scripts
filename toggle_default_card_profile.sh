#!/bin/bash

# Script to toggle between HDMI audio out and laptop speakers

# This script needs following packages to work
# pulseaudio-utils (for pacmd. it is used to set a2dp_sink profile on headset.)
# libnotify-bin (for notify-send. it is used to send toast notifications from CLI.)
# breeze-icon-theme (for card and warning icon)

device_name='HDA Intel PCH'
hdmi_profile='output:hdmi-stereo+input:analog-stereo'
hdmi_profile_friendly_name='HDMI Output + Laptop Mic'
default_profile='output:analog-stereo+input:analog-stereo'
default_profile_friendly_name='Analog Duplex'
card_icon='/usr/share/icons/breeze-dark/devices/64/audio-card.svg'
warning_icon='/usr/share/icons/breeze-dark/status/symbolic/dialog-warning-symbolic.svg'
pa_cmd=$(command -v pacmd)
pulseaudio_card=$(${pa_cmd} list-cards | grep --before-context 5 --max-count 1 "${device_name}" | head -n 1 | cut -f 2 -d ':' | tr -d ' <>')
card_output=${pulseaudio_card/card/output}
current_profile=$(${pa_cmd} list-sinks | grep "${card_output}" | cut -f 4 -d '.' | tr -d ' <>')
target_profile=''
target_profile_friendly_name=''
if [[ "${current_profile}" == 'hdmi-stereo' ]]; then
    target_profile="$default_profile"
    target_profile_friendly_name="$default_profile_friendly_name"
else
    target_profile="$hdmi_profile"
    target_profile_friendly_name="$hdmi_profile_friendly_name"
fi

${pa_cmd} set-card-profile "${pulseaudio_card}" "${target_profile}"
if [[ "$?" -eq 0 ]]; then
    /usr/bin/notify-send --icon=${card_icon} "Toggle Card Profile" "Switched profile to ${target_profile_friendly_name}."
else
    /usr/bin/notify-send --icon=${warning_icon} "Toggle Card Profile" "Failed switching to ${target_profile_friendly_name}."
fi
