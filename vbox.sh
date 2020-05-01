# Start box if not already started and SSH into it on port 2222.
MACHINE_UUID='1c8b5d17-f4a1-4bb2-bd3c-f27f4fe6b69a'
function sshvbox() {
    pid=$(netstat -nl | grep -o ':2222 ')
    if [ "$?" -ne 0 ]; then
        echo 'Starting Virtual Box...'
        /usr/lib/virtualbox/VBoxHeadless --startvm "$MACHINE_UUID" &>/dev/null  &

        echo 'Waiting for 20 secs for machine to bootup.'
        sleep 20
    fi

    ssh -i $HOME/.ssh/id_rsa -p 2222 meow@localhost
}

# Send ACPI shoutdown to known machine.
function killvbox() {
    pid=$(netstat -nl | grep -oP ':2222 ')
    if [ "$?" -eq 0 ]; then
        echo 'Found machine. Sending ACPI shutdown.'
        /usr/bin/VBoxManage controlvm "$MACHINE_UUID" acpipowerbutton
    fi
}
