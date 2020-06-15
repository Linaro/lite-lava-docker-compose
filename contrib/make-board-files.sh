#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: $0 <devices_dir>"
    exit 1
fi

for ser in $1/*.serial; do
    echo "Processing: $ser"
    devname=$(basename $ser .serial)
    devtype=$(echo $devname | python -c "import sys; print(sys.stdin.readline().rsplit('-', 1)[0])")
    contrib/board-setup-helper.py -d $(cat $ser) -t $devtype -b $1/$devname.jinja2 -u >>contrib/LAVA.rules
done
