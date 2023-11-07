#!/bin/sh
# This script created by AQEMU
/usr/bin/qemu-system-x86_64  -soundhw ac97 -machine accel=kvm -m 8192 -cdrom "/home/dghai/downloads/os/windows/3 create-disk/Win10_1809Oct_English_x64_patched_20190324.iso" -hda "/home/dghai/qemu/win10.qcow2" -virtfs local,id=shared_folder_dev_0,path=/home/dghai,security_model=none,mount_tag=shared0 -boot once=d,menu=off -net nic -net user -rtc base=localtime -name "Windows 10" $*
