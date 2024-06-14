#!/bin/sh

release_name=$(lsb_release --codename --short)
release_version=$(lsb_release --short --release)

# setup keyrings dir
sudo install -m 0755 -d /etc/apt/keyrings
# some common packages
sudo apt-get install ca-certificates curl apt-transport-https

##########
# winehq #
##########
# sudo mkdir -pm755 /etc/apt/keyrings
# sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
# sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/$release_name/winehq-$release_name.sources
#
# # installs
# # only 64 bit wine
# sudo apt install --install-recommends libwine
# sudo apt install --no-install-recommends wine64 wine

##########
# docker #
##########
# Add Docker's official GPG key:
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

###########
# firefox #
###########
sudo add-apt-repository ppa:mozillateam/ppa

#############
# keepassxc #
#############
sudo add-apt-repository ppa:phoerious/keepassxc

#############
# syncthing #
#############
sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
# Add the "stable" channel to your APT sources:
echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list

#############
# VS Codium #
#############
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | sudo apt-key add -
sudo apt-add-repository 'deb https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs/ vscodium main'

#################
# broot, rclone #
#################
sudo wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg
echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ stable main" | sudo tee /etc/apt/sources.list.d/azlux-broot-rclone.list

###########
# wezterm #
###########
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

###############
# libreoffice #
###############
sudo add-apt-repository ppa:libreoffice/ppa

############
# kdenlive #
############
sudo add-apt-repository ppa:kdenlive/kdenlive-stable

sudo apt-get update
