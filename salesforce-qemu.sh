sudo qemu-system-x86_64 \
-enable-kvm \
-cpu host \
-m 8G \
-machine ubuntu,accel=kvm,mem-merge=off \
-smp 4,sockets=1,cores=2,threads=2 \
-rtc clock=host,base=localtime \
-usb \
-device qemu-xhci,id=xhci \
-device virtio-tablet,wheel-axis=true \
-soundhw hda \
-netdev user,id=vmnic,smb=/ \
-device virtio-net,netdev=vmnic \
-drive file=/usr/share/OVMF/OVMF_CODE.fd,if=pflash,format=raw,unit=0,readonly=on \
-drive file=$HOME/qemu/salesforce.nvram,if=pflash,format=raw,unit=1 \
-drive file=/dev/nvme0n1,index=0,media=disk,driver=raw 

#-cdrom $HOME/downloads/os/kubuntu-20.04.3-desktop-amd64.iso
# -mem-path /dev/hugepages \
# -vga qxl -display none -serial mon:stdio \
# -soundhw ac97 \
# -netdev user,id=vmnic,smb=/ \
# -device qemu-xhci,id=xhci \
# https://k3a.me/boot-windows-partition-virtually-kvm-uefi/
#
