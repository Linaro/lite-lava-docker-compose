#!/bin/sh

init_services() {
    echo "* Starting rpcbind"
    mkdir -p /run/sendsigs.omit.d/
    service rpcbind start
    echo "* Starting nfs-common"
    service nfs-common start
    echo "* Starting dbus"
    mkdir -p /var/run/dbus
    chmod 755 /var/run/dbus
    rm -f /var/run/dbus/*
    rm -f /var/run/messagebus.pid
    dbus-uuidgen --ensure
    dbus-daemon --system --fork
    sleep 1
}

init_services
exec /usr/bin/ganesha.nfsd -F -L /dev/stdout -f /etc/ganesha/ganesha.conf
