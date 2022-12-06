#!/bin/sh

# Script to kill dangling sessions with same login as the user.
for session in $(/usr/bin/loginctl list-sessions --output=json --no-pager | jq ".[] | select(.user == \"$USER\") | .session" | tr -d '"'); do
    state=$(/usr/bin/loginctl session-status $session | grep -oP 'State: .+' | cut -f 2 -d ' ')
    echo "$state"; [ "$state" != "active" ] && /usr/bin/loginctl kill-session $session
done

/usr/bin/notify-send "Sessions" "$(/usr/bin/loginctl list-sessions)"
