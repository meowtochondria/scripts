#!/bin/bash -x
# Updating certs using API - https://api.docs.cpanel.net/openapi/cpanel/operation/install_ssl/

export NAMECHEAP_DEBUG=true
KEEPASSXC_DB="$HOME/Keepassxc/keepass2.kdbx"
KEEPASSXC_CLI=$(command -v keepassxc-cli)
LEGO_CLI=$(command -v lego)

test -f "$KEEPASSXC_DB" || (echo "$KEEPASSXC_DB not found! Exiting." && exit 3)
test -z "$KEEPASSXC_CLI" && echo "keepassxc-cli not found! Exiting." && exit 4
test -z "$LEGO_CLI" && echo "lego (https://github.com/go-acme/lego) not found! Exiting." && exit 5

read -s -p "KeepassXC password: " KEEPASS
echo

test -z "$KEEPASS" && echo "Empty password. Exiting." && exit 1

CPANEL_API_TOKEN=$($KEEPASSXC_CLI show --quiet --attributes password $KEEPASSXC_DB '/Home/Namecheap CPanel API' <<< $KEEPASS)
# See if we have the entry we want before proceeding. Acts as a check for password validity as well.
test -z "$CPANEL_API_TOKEN" && echo "Couldn't fetch CPanel token. Wrong password or entry moved?" && exit 2

# export is required for these 3 variables because lego expects these variables in env.
export CLOUDFLARE_DNS_API_TOKEN=$($KEEPASSXC_CLI show --quiet --attributes password $KEEPASSXC_DB '/Home/Cloudflare DNS API token' <<< $KEEPASS)
export NAMECHEAP_API_KEY=$($KEEPASSXC_CLI show --quiet --attributes password $KEEPASSXC_DB '/Home/Namecheap API' <<< $KEEPASS)
export NAMECHEAP_API_USER=$($KEEPASSXC_CLI show --quiet --attributes username $KEEPASSXC_DB '/Home/Namecheap API' <<< $KEEPASS)

EMAIL=$($KEEPASSXC_CLI show --quiet --attributes username $KEEPASSXC_DB '/Home/LetsEncrypt' <<< $KEEPASS)
# Setup LetsEncrypt account in a way that lego expects.
mkdir -p $PWD/accounts/acme-v02.api.letsencrypt.org/${EMAIL}/keys
# setup key
if [ ! -s "$PWD/accounts/acme-v02.api.letsencrypt.org/${EMAIL}/keys/${EMAIL}.key" ]; then
    $KEEPASSXC_CLI show --quiet --attributes key $KEEPASSXC_DB '/Home/LetsEncrypt' <<< $KEEPASS > $PWD/accounts/acme-v02.api.letsencrypt.org/${EMAIL}/keys/${EMAIL}.key
fi

# setup accounts file
if [ ! -s "$PWD/accounts/acme-v02.api.letsencrypt.org/${EMAIL}/account.json" ]; then
    $KEEPASSXC_CLI show --quiet --attributes account_json $KEEPASSXC_DB '/Home/LetsEncrypt' <<< $KEEPASS > $PWD/accounts/acme-v02.api.letsencrypt.org/${EMAIL}/account.json
fi

# Remove password from memory as its work is done
unset KEEPASS
# Get new certificate using lego
$LEGO_CLI --email=${EMAIL} --domains=devghai.com --domains=cal.devghai.com --domains=cpanel.devghai.com --domains=mail.devghai.com --domains=webdisk.devghai.com --domains=webmail.devghai.com --domains=www.devghai.com --domains=autodiscover.devghai.com  --domains=ghai.co --domains=autodiscover.ghai.co  --domains=cpanel.ghai.co --domains=mail.ghai.co --domains=webdisk.ghai.co --domains=webmail.ghai.co --domains=www.ghai.co --domains=cloud.devghai.com --domains=www.cloud.devghai.com --domains=git.devghai.com --domains=www.git.devghai.com --domains=src.devghai.com --domains=www.src.devghai.com --dns=cloudflare --path $PWD --key-type rsa4096 run --no-bundle

# update all domains
for domain in devghai.com ghai.co cloud.devghai.com git.devghai.com src.devghai.com; do
    curl -H "Content-Type: text/plain" -H "Authorization: cpanel devgosxk:$CPANEL_API_TOKEN" "https://premium59.web-hosting.com:2083/execute/SSL/install_ssl" --data "domain=$domain" --data-urlencode "cert@certificates/devghai.com.crt" --data-urlencode "key@certificates/devghai.com.key" | jq .
done

unset NAMECHEAP_API_KEY
unset NAMECHEAP_API_USER
unset NAMECHEAP_DEBUG
unset CLOUDFLARE_DNS_API_TOKEN
unset CPANEL_API_TOKEN
rm -rf "$PWD/accounts"
