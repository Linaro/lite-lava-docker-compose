#!/usr/bin/python3

#  Copyright 2019 Linaro Limited
#  Copyright (c) 2014 Taeyeon Mori (for MurmurHash2 code)

#  Author: Kumar Gala <kumar.gala@linaro.org>

#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
#  The MurmurHash2 implementation is take from:
#  https://github.com/Orochimarufan/cdev/blob/master/cdev/murmurhash2.py
#
#  UDEV event forwarding to a container
#
#  based on https://github.com/eiz/udevfw

import os
import sys
import socket
import pyudev
import syslog
import threading
import docker
import queue
import array
from struct import *
from ctypes import CDLL
import argparse

NETLINK_KOBJECT_UEVENT = 15
UDEV_MONITOR_UDEV  = 2
CLONE_NEWNET = 0x40000000
UDEV_MONITOR_MAGIC = 0xFEEDCAFE

containers = {}

class containersClass:
    def __init__(self):
        self.thread = threading.Thread()
        self.wq = queue.Queue()

if array.array('L').itemsize == 4:
    uint32_t = 'L'
elif array.array('I').itemsize == 4:
    uint32_t = 'I'
else:
    raise ImportError("Could not determine 4-byte array code!")

def MurmurHash2(input, seed=0):
    """
    Generate a 32-bit hash from a string using the MurmurHash2 algorithm

    takes a bytestring!

    Pure-python implementation.
    """
    l = len(input)

    # m and r are mixing constants generated offline
    # They're not really magic, they just happen to work well
    m = 0x5bd1e995
    #r = 24

    # Initialize the hash to a "random" value
    h = seed ^ l

    # Mix 4 bytes at a time into the hash
    x = l % 4
    o = l - x

    for k in array.array(uint32_t, input[:o]):
        # Original Algorithm
        #k *= m;
        #k ^= k >> r;
        #k *= m;

        #h *= m;
        #h ^= k;

        # My Algorithm
        k = (k * m) & 0xFFFFFFFF
        h = (((k ^ (k >> 24)) * m) ^ (h * m)) & 0xFFFFFFFF

        # Explanation: We need to keep it 32-bit. There are a few rules:
        # 1. Inputs to >> must be truncated, it never overflows
        # 2. Inputs to * must be truncated, it may overflow
        # 3. Inputs to ^ may be overflowed, it overflows if any input was overflowed
        # 4. The end result must be truncated
        # Therefore:
        # b = k * m -> may overflow, we truncate it because b >> r cannot take overflowed data
        # c = b ^ (b >> r) -> never overflows, as b is truncated and >> never does
        # h = (c * m) ^ (h * m) -> both inputs to ^ may overflow, but since ^ can take it, we truncate once afterwards.

    # Handle the last few bytes of the input array
    if x > 0:
        if x > 2:
            h ^= input[o+2] << 16
        if x > 1:
            h ^= input[o+1] << 8
        h = ((h ^ input[o]) * m) & 0xFFFFFFFF

    # Do a few final mixes of the hash to ensure the last few
    # bytes are well incorporated

    # Original:
    #h ^= h >> 13;
    #h *= m;
    #h ^= h >> 15;

    h = ((h ^ (h >> 13)) * m) & 0xFFFFFFFF
    return (h ^ (h >> 15))

def bloomHash(tag):
    bits = 0
    hash = MurmurHash2(tag.encode())

    bits = bits | 1 << (hash & 63)
    bits = bits | 1 << ((hash >> 6) & 63)
    bits = bits | 1 << ((hash >> 12) & 63)
    bits = bits | 1 << ((hash >> 18) & 63)

    return bits


def buildHeader(proplen, subsys, devtype, taghash):
    header_fmt = "8s8I"
    header_size = calcsize(header_fmt)
    subsys_hash = 0
    devtype_hash = 0

    if subsys:
        subsys_hash = socket.htonl(MurmurHash2(subsys.encode()))

    if devtype:
        devtype_hash = socket.htonl(MurmurHash2(devtype.encode()))

    tag_low = socket.htonl(taghash & 0xffffffff)
    tag_high = socket.htonl(taghash >> 32)

    return pack(header_fmt, b"libudev", socket.htonl(UDEV_MONITOR_MAGIC),
                header_size, header_size, proplen, subsys_hash, devtype_hash,
                tag_low, tag_high)


def BuildPacket(dev):
    subsys = dev.subsystem
    devtype = dev.device_type

    proplist = bytearray()
    for p in dev.properties:
        proppair = p + "=" + dev.properties[p]
        proplist = proplist + proppair.encode() + bytes([0])

    tag_hash = 0
    for t in dev.tags:
        tag_hash = tag_hash | bloomHash(t)

    hdr = buildHeader(len(proplist), subsys, devtype, tag_hash)

    return hdr + proplist

def errcheck(ret, func, args):
    if ret == -1:
        e = get_errno()
        raise OSError(e, os.strerror(e))

def sendMsgThread(inst, netns_file):
    nsfd = open(netns_file, "r")
    libc = CDLL('libc.so.6', use_errno=True)
    libc.setns.errcheck = errcheck
    libc.setns(nsfd.fileno(), CLONE_NEWNET)
    sendfd = socket.socket(socket.AF_NETLINK, socket.SOCK_RAW|socket.SOCK_NONBLOCK, NETLINK_KOBJECT_UEVENT)
    if options.debug:
        print(sendfd)

    while True:
        (work_type, pkt) = containers[inst].wq.get()

        if work_type == "PKT":
            # Older kernels (like 4.15 on Ubuntu 18.04) return ECONNREFUSED
            # to work around this we just ignore this specific error as the
            # data still is send on the socket.
            try:
                sendfd.sendto(pkt, (0, UDEV_MONITOR_UDEV))
            except ConnectionRefusedError:
                pass

        if work_type == "DOCKER":
            nsfd.close()
            break

def udev_event_callback(dev):
    if options.debug:
        print('background event {0.action}: {0.device_path}'.format(dev))
    for i in containers:
        if containers[i].thread.is_alive():
            containers[i].wq.put(("PKT", BuildPacket(dev)))

def start_up_thread(name):
    container = client.containers.get(name)
    ns_filename = container.attrs['NetworkSettings']['SandboxKey']
    if options.debug:
        print("DBG: Container[%s] netns file %s" % (name, ns_filename))
    containers[name] = containersClass()
    containers[name].thread = threading.Thread(name=name, target=sendMsgThread, args=(name, ns_filename))
    containers[name].thread.start()

def main():
    parser = argparse.ArgumentParser(description='USB device passthrough for docker containers', add_help=False)

    parser.add_argument("-i", "--instance", type=str, required=True, action='append',
                        help="Docker instance", dest="names")

    parser.add_argument("-d", "--debug", action="store_true",
                        help="Enable Debug Loggin")

    global options
    options = parser.parse_args()

    context = pyudev.Context()
    if options.debug:
        context.log_priority = syslog.LOG_DEBUG
    monitor = pyudev.Monitor.from_netlink(context)
    observer = pyudev.MonitorObserver(monitor, callback=udev_event_callback, name='monitor-observer')

    observer.start()

    global client

    client = docker.from_env()

    # If the container is running get the namespace file (SandboxKey)
    # and startup the sendMsgThread
    f = {'name': options.names, 'status': 'running'}
    if client.containers.list(filters=f):
        for name in options.names:
            start_up_thread(name)

    # Watch for docker events to startup or shutdown a new sendMsgThread
    f = {'type': 'container', 'event': ['start', 'stop'], 'container': options.names }
    try:
        for event in client.events(decode=True, filters=f):
            name = event['Actor']['Attributes']['name']
            if options.debug:
                print("DOCKER: %s for %s" % (event['Action'], name))
            if event['Action'] == 'start':
                start_up_thread(name)
            if event['Action'] == 'stop':
                containers[name].wq.put(("DOCKER", event['Action']))
                containers[name].thread.join()
    except KeyboardInterrupt:
        for i in containers:
            if containers[i].thread.is_alive():
                containers[i].wq.put(("DOCKER", 'stop'))


if __name__ == '__main__':
    main()
