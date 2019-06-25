#!/usr/bin/python3

#  Copyright 2019 Linaro Limited
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

import pyudev
import argparse
import os
import pprint

def ser2net(dev, ser2net_file):
    ser2net = {}
    port_num = 5001

    with open(ser2net_file, 'r') as fd:
        for line in fd:
            line = line.strip()
            values = line.split(':')
            port = int(values.pop(0))
            ser2net[port] = values

    if len(ser2net):
        port_num = max(ser2net.keys()) + 1

    new_device = True

    for k in ser2net:
        if dev in ser2net[k][2]:
            new_device = False
            print("WARNING: device %s already exists in %s on port %d" % (dev, ser2net_file, k))
            port_num = k

    if new_device:
        with open(ser2net_file, 'a') as fd:
            fd.write("%d:telnet:0:%s:115200 8DATABITS NONE 1STOPBIT LOCAL max-connections=10\n" % (port_num, dev))

    return port_num

def get_device_numbers(serial_no, dev_type, board_file, ser2net_file):
    result = None, None
    context = pyudev.Context()

    devices = context.list_devices()

    board_jinja = open(board_file, 'w')

    board_jinja.write("{%% extends '%s.jinja2' %%}\n" % dev_type)
    board_jinja.write("{%% set board_id = '%s' %%}\n" % serial_no)

    for device in devices:
        serial = device.attributes.get("serial")
        if serial is not None and serial_no in serial.decode("utf-8"):
            child = device.children
            for c in child:
                if (c.subsystem == "block"):
                    for l in c.device_links:
                        if "by-id" in l:
                            board_jinja.write("{%% set usb_mass_device = '%s' %%}\n" % l)

                if (c.subsystem == "tty"):
                    for l in c.device_links:
                        if "by-id" in l:
                            port = ser2net(l, ser2net_file)
                            if port:
                                board_jinja.write("{%% set connection_command = 'telnet ser2net %d' %%}\n" % port)
            break

    if dev_type == "frdm-k64f":
        board_jinja.write("{% set resets_after_flash = false %}\n")


def main():
    parser = argparse.ArgumentParser(description='LAVA board helper', add_help=False)

    parser.add_argument("-d", "--device_serial_num", type=str, required=True,
                        help="Devices serial number")

    parser.add_argument("-t", "--device_type", type=str, required=True,
                        help="Devices type")

    parser.add_argument("-s", "--ser2net_conf", type=str, required=False,
                        default = "./ser2net/ser2net.conf",
                        help="ser2net configuration file")

    parser.add_argument("-u", dest='udev', default=False, action='store_true')

    parser.add_argument("-b", "--board_file", type=str, required=False,
                        default = "board.jinja2",
                        help="board jinja file")

    options = parser.parse_args()

    get_device_numbers(options.device_serial_num, options.device_type,
                       options.board_file, options.ser2net_conf)

    if (options.udev):
        print('ACTION=="add", ENV{ID_SERIAL_SHORT}=="%s", RUN+="/usr/local/bin/usb-passthrough -a -d %%E{ID_SERIAL_SHORT} -i lava-dispatcher"' % options.device_serial_num)
        print('ACTION=="add", SUBSYSTEM=="tty", ENV{ID_SERIAL_SHORT}=="%s", RUN+="/usr/local/bin/usb-passthrough -a -d %%E{ID_SERIAL_SHORT} -i lava-ser2net"' % options.device_serial_num)



if __name__ == '__main__':
    main()
