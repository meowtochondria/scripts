#!/bin/sh

grep --quiet --no-messages open /proc/acpi/button/lid/LID/state

# Ubuntu: Create a file with following contents at /usr/share/pam-configs/laptop-lid
######
# Name: Disable fingerprint when laptop lid is closed.
# Default: no
# Priority: 261
# Conflicts: fprint
# Auth-Type: Primary
# Auth:
#         [success=ignore default=1]      pam_exec.so quiet /home/dev/src/scripts/pam-check-lid.sh
#######
#
# `Priority: <number>` <number> has to be one greater than that in /usr/share/pam-configs/fprintd
#
# Execute `sudo pam-auth-update`
#
# Other OSes: Ensure following is the first line in /etc/pam.d/common-auth, or above the line specifying fprtind:
#######
# auth    [success=ignore default=1]  pam_exec.so quiet /home/dev/src/scripts/pam-check-lid.sh

# LOGIC: https://unix.stackexchange.com/questions/678609/how-to-disable-fingerprint-authentication-when-laptop-lid-is-closed/743941#743941
#
#
