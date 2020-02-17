#!/bin/sh
#
# This script can be used to build a test SD card image, using Docker Yocto
# image for OpenAMP.
#

set -ex

# This must be owned by $UID from Dockerfile.
mkdir -p downloads
mkdir -p openamp
cd openamp

if [ ! -d open-amp ]; then
    git clone https://github.com/OpenAMP/open-amp
fi
if [ ! -d libmetal ]; then
    git clone https://github.com/OpenAMP/libmetal
fi
if [ ! -d embeddedsw ]; then
    git clone https://github.com/Xilinx/embeddedsw
fi

cd ..

rm -f xilinx-openamp-build.cid

docker run -it --cidfile xilinx-openamp-build.cid \
    -v $PWD/downloads:/home/build/prj/build/downloads \
    -v $PWD/openamp:/home/build/prj/openamp \
    pfalcon/xilinx-openamp-build:v3 \
    /bin/bash -c "cd ~/prj; source setupsdk; MACHINE=zcu102-zynqmp bitbake openamp-image-minimal"

cid=$(cat xilinx-openamp-build.cid)
docker cp -L $cid:/home/build/prj/build/tmp/deploy/images/zcu102-zynqmp/openamp-image-minimal-zcu102-zynqmp.wic.qemu-sd .


#docker commit $cid pfalcon/xilinx-openamp-build:v17-built
