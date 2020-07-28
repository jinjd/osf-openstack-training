#!/bin/bash

set -ex

if [[ ! $SERVER_IP ]]
then
        echo "Please use $SERVER_IP set the IP address of the need to monitor."
        exit 1
elif [[ ! $DHCP_RANGE ]]
then
        echo "Please use $DHCP_RANGE set up DHCP network segment."
        exit 1
elif [[ ! $ROOT_PASSWORD ]]
then
        echo "Please use $ROOT_PASSWORD set the root password."
        exit 1
elif [[ ! $DHCP_SUBNET ]]
then
        echo "Please use $DHCP_SUBNET set the dhcp subnet."
        exit 1
elif [[ ! $DHCP_ROUTER ]]
then
        echo "Please use $DHCP_ROUTER set the dhcp router."
        exit 1
elif [[ ! $DHCP_DNS ]]
then
        echo "Please use $DHCP_DNS set the dhcp dns."
        exit 1
elif [[ ! $HTTP_PORT ]]
then
        echo "Please use $HTTP_PORT set the http port."
        exit 1
elif [[ ! $PXE_DEFAULT_MENU ]]
then
        echo "Please use $PXE_DEFAULT_MENU set the pxe default menu"
        exit 1
else
        PASSWORD=`openssl passwd -1 -salt hLGoLIZR $ROOT_PASSWORD`
        sed -i "s/^server: 127.0.0.1/server: $SERVER_IP/g" /etc/cobbler/settings
        sed -i "s/^next_server: 127.0.0.1/next_server: $SERVER_IP/g" /etc/cobbler/settings
        sed -i 's/pxe_just_once: 0/pxe_just_once: 1/g' /etc/cobbler/settings
        sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings
	sed -i "s/http_port: 80/http_port: $HTTP_PORT/" /etc/cobbler/settings
        sed -i "s#^default_password.*#default_password_crypted: \"$PASSWORD\"#g" /etc/cobbler/settings
        sed -i "s/192.168.1.0/$DHCP_SUBNET/" /etc/cobbler/dhcp.template
        sed -i "s/192.168.1.5/$DHCP_ROUTER/" /etc/cobbler/dhcp.template
        sed -i "s/192.168.1.1;/$DHCP_DNS;/" /etc/cobbler/dhcp.template
        sed -i "s/192.168.1.100 192.168.1.254/$DHCP_RANGE/" /etc/cobbler/dhcp.template
	sed -i "s/00:02/00:09/" /etc/cobbler/dhcp.template
	sed -i "s#ia64/elilo.efi#grub/grub-x86_64.efi#" /etc/cobbler/dhcp.template
        sed -i "s/^Listen 80/Listen $HTTP_PORT/" /etc/httpd/conf/httpd.conf
        sed -i "s/^#ServerName www.example.com:80/ServerName localhost:$HTTP_PORT/" /etc/httpd/conf/httpd.conf
        sed -i "s/service %s restart/supervisorctl restart %s/g" /usr/lib/python2.7/site-packages/cobbler/modules/sync_post_restart_services.py
	case $PXE_DEFAULT_MENU in
		1)
			sed -i "s/ONTIMEOUT.*/ONTIMEOUT local/" /etc/cobbler/pxe/pxedefault.template
		;;
		2)
			sed -i "s/ONTIMEOUT.*/ONTIMEOUT bootstrap-x86_64/" /etc/cobbler/pxe/pxedefault.template
		;;
		3)
			sed -i "s/ONTIMEOUT.*/ONTIMEOUT icos-5.6-x86_64/" /etc/cobbler/pxe/pxedefault.template
			sed -i "s/default=0/default=1/" /etc/cobbler/pxe/efidefault.template
		;;
		*) ;;
	esac
        rm -rf /run/httpd/*
        /usr/sbin/apachectl
        /usr/bin/cobblerd

        #cobbler get-loaders
        cobbler sync

	cobbler import --name=bootstrap --path=/mnt/bootstrap  --arch=x86_64 
	cobbler import --name=icos-5.6 --path=/mnt/icos --kickstart=/var/lib/cobbler/kickstarts/ICOS.ks   --arch=x86_64 
	cobbler profile edit --name=icos-5.6-x86_64 --kopts="inst.gpt"

        pkill cobblerd
        pkill httpd
        rm -rf /run/httpd/*
        
        exec supervisord -n -c /etc/supervisord.conf
fi
