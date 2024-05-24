# NGINX

NGINX fronts web configurator and its config is built in `/etc/inc/system.inc`. Its a PHP file. Look for function called `system_generate_nginx_config`. It can be used to modify which interfaces web configurator listens on. NGINX config is at `/var/etc/nginx-webConfigurator.conf`. Restart NGINX using `/etc/rc.restart_webgui`.

# Adding a new service accessible publicly
1. Add a NAT/port fowarding for port. it will also setup firewall rule.
2. To access service from internal network when external DNS resolves to WAN IP, setup a DNS override: https://docs.netgate.com/pfsense/en/latest/nat/reflection.html#split-dns
