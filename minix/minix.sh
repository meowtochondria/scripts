# ubuntu-minimal-22.04

sudo apt install man man-db manpages bash-completion vim python3 python3-pip mlocate dnsutils netcat apt-utils dialog net-tools apt-file

# fix man in ubuntu-minimal
test -x /usr/bin/man.REAL && sudo mv /usr/bin/man{.REAL,}
sudo systemctl start man-db.service

# remove useless motd
sudo rm /etc/update-motd.d/60-unminimize /etc/update-motd.d/10-help-text
echo "ENABLED=0" | sudo tee -a /etc/default/motd-news

# Update ntp pool. Make sure firewall allows egress on port 123
sudo mkdir /etc/systemd/timesyncd.conf.d

echo -e "[Time]\nNTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org\nFallbackNTP=ntp.ubuntu.com" | sudo tee -a /etc/systemd/timesyncd.conf.d/pools.conf

sudo systemctl restart systemd-timesyncd.service
timedatectl set-ntp true

# mounting USB devices. unmount using pumount
sudo apt install pmount
usb_device='/dev/sda' # find using lsblk
for d in $(lsblk --output path,label --list --noheadings $usb_device | tail -n +2 | tr -s ' ' ','); do path=${d%,*}; label=${d#*,}; pmount $path $label; echo "path=$path; label=$label; mountpoint=/media/$label"; done
# other packages to install that do not have repos
# caddy, cloudflared

# cloudflared
# 1. install
# 2. setup config
# 3. cloudflared service install

# caddy is not needed if using cloudflare tunnels. no https management is needed either.

##### PIPX to install python packages in dedicated venv #####
sudo apt install pipx
sudo mkdir -p /opt/pipx/bin
sudo chmod -R a+rwx /opt/pipx
echo -e 'export PIPX_HOME="/opt/pipx"\nexport PIPX_BIN_DIR="$PIPX_HOME/bin"\n[[ "$PATH" == *"$PIPX_BIN_DIR"* ]] || export PATH="$PIPX_BIN_DIR:$PATH"' | sudo tee -a /etc/profile.d/pipx.sh

##### VDIRSYNCER using PIPX #####
pipx install vdirsyncer
pipx inject vdirsyncer aiohttp-oauthlib
sudo adduser --system --no-create-home --disabled-login --group vdirsyncer
sudo install --directory --group=vdirsyncer --owner=vdirsyncer /etc/vdirsyncer
sudo install --directory --group=vdirsyncer --owner=vdirsyncer /var/log/vdirsyncer
sudo install --directory --group=vdirsyncer --owner=vdirsyncer /var/lib/vdirsyncer

# SCP config file to /etc/vdirsyncer/config
scp ./vdirsyncer/config minix:~/vdirsyncer.config
scp ./vdirsyncer/gcal_token minix:~/gcal_token
sudo mv ~/vdirsyncer.config /etc/vdirsyncer/config
sudo mv ~/gcal_token /etc/vdirsyncer/gcal_token
sudo chown vdirsyncer:vdirsyncer /etc/vdirsyncer/*

# SCP systemd files
scp ./vdirsyncer/etc.systemd.system.vdirsyncer.service minix:~/vdirsyncer.service
scp ./vdirsyncer/etc.systemd.system.vdirsyncer.timer minix:~/vdirsyncer.timer
sudo mv ~/vdirsyncer.service /etc/systemd/system/
sudo mv ~/vdirsyncer.timer /etc/systemd/system/

