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

# Group for radicale and vdirsyncer. This is used in systemd definitions.
sudo addgroup cal
sudo adduser --system --no-create-home --disabled-login --ingroup=cal cal

##### VDIRSYNCER using PIPX #####
pipx install vdirsyncer
pipx inject vdirsyncer aiohttp-oauthlib
sudo install --directory --owner=cal --group=cal /etc/vdirsyncer
sudo install --directory --owner=cal --group=cal /var/log/vdirsyncer
sudo install --directory --owner=cal --group=cal /var/lib/calendar/vdirsyncer

# SCP config file to /etc/vdirsyncer/config
# scp ./vdirsyncer/config minix:~/vdirsyncer.config
# scp ./vdirsyncer/gcal_token minix:~/gcal_token
sudo mv ~/vdirsyncer.config /etc/vdirsyncer/config
sudo mv ~/gcal_token /var/lib/vdirsyncer/gcal_token
sudo chown cal:cal /etc/vdirsyncer/*

# SCP systemd files
scp ./vdirsyncer/etc.systemd.system.vdirsyncer.service minix:~/vdirsyncer.service
scp ./vdirsyncer/etc.systemd.system.vdirsyncer.timer minix:~/vdirsyncer.timer
sudo mv ~/vdirsyncer.service /etc/systemd/system/
sudo mv ~/vdirsyncer.timer /etc/systemd/system/

# Reload systemctl and start service
sudo systemctl daemon-reload
sudo systemctl enable vdirsyncer.{timer,service}
sudo systemctl start vdirsyncer.{timer,service}

##### RADICALE using PIPX #####
pipx install radicale
pipx inject radicale https://github.com/Unrud/RadicaleInfCloud/archive/master.tar.gz

sudo adduser --system --no-create-home --disabled-login --ingroup cal cal
sudo install --directory --owner=cal --group=cal /etc/radicale
sudo install --directory --owner=cal --group=cal /var/log/radicale
sudo install --directory --owner=cal --group=cal /var/lib/calendar/radicale

# SCP config file to /etc/radicale/config
# scp ./radicale/config minix:~/radicale.config
sudo mv ~/radicale.config /etc/radicale/config
sudo chown cal:cal /etc/radicale/*

# SCP systemd files
# scp ./radicale/etc.systemd.system.radicale.service minix:~/radicale.service
sudo mv ~/radicale.service /etc/systemd/system/

# Reload systemctl and start service
sudo systemctl daemon-reload
sudo systemctl enable radicale.service
sudo systemctl start radicale.service

# SETUP BETWEEN VDIRSYNCER AND RADICALE:
# vdirsyncer syncs normally to its own directory.
# radicale has a link pointing to calendar i want to expose into vdirsyncer directory.
# However, radicale needs one file and one directory in calendar directory which we will
# create using commands.
# This setup is as optimal as it can get to do as few network requests as possible on an
# Atom powered fanless machine.
# Caveat is that if a radicale sync is happening to modify an event, and vdirsyncer sync
# is happening at the same time, then the behavior is undefined. I am not planning to
# modify events in exposed calendar using radicale.

# MANUAL STEPS TO SETUP CALENDAR AND LINKING VDIRSYNCER TO RADICALE
sudo -Hu cal /opt/pipx/bin/vdirsyncer --config /etc/vdirsyncer/config discover
# say yes and then do first sync
sudo systemctl start vdirsyncer && sudo journalctl --follow -xeu vdirsyncer

# at this point, /var/lib/vdirsyncer/calendars should contain the calendar i want to expose using radicale.
# now create the file and direcory that radicale needs.
echo '{"C:calendar-description": "work calendar", "C:supported-calendar-component-set": "VEVENT,VJOURNAL,VTODO", "D:displayname": "okta", "ICAL:calendar-color": "#2958ceff", "tag": "VCALENDAR"}' | sudo -u cal tee -a /var/lib/calendar/vdirsyncer/calendars/okta/.Radicale.props
sudo chmod 0600 /var/lib/calendar/vdirsyncer/calendars/okta/.Radicale.props
sudo install --directory --owner=cal --group=cal /var/lib/calendar/vdirsyncer/calendars/okta/.Radicale.cache


# now link it. this expects a user called dev to exist, and so does the directory
sudo install --directory --group=cal --owner=cal /var/lib/calendar/radicale/collections/collection-root/dev/
sudo -Hu cal ln -sT /var/lib/calendar/vdirsyncer/calendars/okta /var/lib/calendar/radicale/collections/collection-root/dev/okta


