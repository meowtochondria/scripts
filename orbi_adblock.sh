#!/bin/sh

base_dir="$HOME"
cd "$base_dir"

# Download the package from openwrt repo
wget -O "$base_dir/packages.zip" --no-check-certificate  https://codeload.github.com/openwrt/packages/zip/for-15.05
zip_dir='packages-for-15.05/net/adblock/files'

# Extract just the adblock files
unzip "$base_dir/packages.zip" "$zip_dir/*" -d "$base_dir/adblock"
unzip_dir="$base_dir/adblock/$zip_dir"

# Do installation per https://github.com/openwrt/packages/blob/master/net/adblock/Makefile
conf_dir="/etc/adblock"; bin_dir="/usr/bin"; svc_dir="/etc/init.d"; hotplug_dir="/etc/hotplug.d/iface"; app_config_dir="/etc/config"; www_dir="/www/adblock"

# conf files
mkdir -p "$conf_dir"; cp "$unzip_dir/adblock.whitelist" "$conf_dir/"; cp "$unzip_dir/adblock.blacklist" "$conf_dir/"; cp "$unzip_dir/adblock.conf" "$conf_dir/"

# binary
cp "$unzip_dir/adblock-update.sh" "$bin_dir/"; cp "$unzip_dir/adblock-helper.sh" "$bin_dir/"

# hotplug
cp "$unzip_dir/adblock.hotplug" "$hotplug_dir/90-adblock"

# service definition
cp "$unzip_dir/adblock.init" "$svc_dir/adblock"

# application config
cp "$unzip_dir/adblock.conf" "$app_config_dir/adblock"

# Set adblock to use wget without ssl to download blocklists
# sed -i'' 's/uclient-fetch/wget-nossl/g' "$app_config_dir/adblock"

# www
mkdir -p "$www_dir"; cp $unzip_dir/www/adblock/* "$www_dir/"

# uninstall
unlink /etc/rc.d/S30adblock; rm -rf "$conf_dir"; rm "$bin_dir/adblock*.sh"; rm "$svc_dir/adblock"; rm "$app_config_dir/adblock"; rm "$hotplug_dir/90-adblock"; rm -rf "$www_dir/"; rm /var/run/adblock.pid
