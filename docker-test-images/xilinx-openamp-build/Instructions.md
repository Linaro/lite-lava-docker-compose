This document explains how to set up an OpenAMP build system using the
tools and source code available on the Xilinx GitHub repositories. This
will give you a reasonably complete Linux distribution running on the
A53s and demo firmware for the R5s. It's configured to build for the
Xilinx ZCU102 board, which is also what the Xilinx QEMU Docker container
emulates.

This uses Yocto, so for those familiar with Yocto, this will be old hat,
except for the contents of some files and the particulars of the custom
configuration.

This is not a small installation. It takes about 50 GB of disk, and a lot of 
free space for temporary files.

# Getting the basic build environment

[This is taken from https://github.com/Xilinx/yocto-manifests/blob/rel-v2021.2/README.md]

Getting Started
---------------
**1.  Install Repo.**

Download the Repo script:

    $ curl -k https://storage.googleapis.com/git-repo-downloads/repo > repo

Make it executable:

    $ chmod a+x repo

Move it on to your system path:

    $ sudo mv repo /usr/local/bin/

If it is correctly installed, you should see a Usage message when invoked
with the help flag.

    $ repo --help

**2.  Initialize a Repo client.**

Create an empty directory to hold your working files:

    $ XILINX_SOURCES=/path/to/xilinx/sources
    $ mkdir -p $XILINX_SOURCES
    $ cd $XILINX_SOURCES

To use the release branch, type:

    $ repo init -u git://github.com/Xilinx/yocto-manifests.git -b rel-v2019.2

A successful initialization will end with a message stating that Repo is
initialized in your working directory. Your directory should now contain a
.repo directory where repo control files such as the manifest are stored but
you should not need to touch this directory.

To learn more about repo, look at http://source.android.com/source/version-control.html
***

**3.  Fetch all the repositories:**

    $ repo sync

Now go turn on the coffee machine as this may take 20 minutes depending on your
connection.

Staying Up to Date
------------------
To pick up the latest changes for all source repositories, run:

    $ repo sync

# Setting Up the SDK

To setup the environment for the Yocto build, run 

    $ source setupsdk

in the directory you created the repository in. This will create a directory called 'build', cd you into it, and set up a default configuration.

# Adding custom directories for OpenAMP development

The Yocto repository that gets built in the first step doesn't make it possible to develop OpenAMP binaries directly. To allow for this (from the build directory)

    $ cd ..
    $ mkdir openamp
    $ cd openamp
    $ git clone <open-amp repo of your choice>
    $ git clone <libmetal repo of your choice>
    $ git clone https://github.com/Xilinx/embeddedsw
    $ cd ../../build

The embeddedsw repository contains copies of the libmetal and open-amp trees, along with the code needed to build the R5 BSP using the Xilinx toolchain.

Then you need to edit conf/local.conf to add the following lines:


	INHERIT += "externalsrc"

	PREFERRED_PROVIDER_virtual/open-amp = "open-amp"
	PREFERRED_PROVIDER_virtual/libmetal = "libmetal"
	EXTERNALSRC_pn-open-amp = "/<path to repo>/openamp/open-amp"
	EXTERNALSRC_pn-libmetal = "/<path to repo>/openamp/libmetal"
	RM_WORK_EXCLUDE += "open-amp"
	RM_WORK_EXCLUDE += "libmetal"
	PREFERRED_PROVIDER_virtual/openamp-fw-echo-testd = "openamp-fw-echo-testd"
	EXTERNALSRC_pn-openamp-fw-echo-testd = "/<path to repo>/openamp/embeddedsw"
	RM_WORK_EXCLUDE += "openamp-fw-echo-testd"

	DISTRO_FEATURES_append = " openamp "

	IMAGE_INSTALL_append = " open-amp kernel-modules open-amp-demos packagegroup-petalinux-openamp "
	CORE_IMAGE_EXTRA_INSTALL_append = " open-amp kernel-modules open-amp-demos "

# Creatiing the custom device tree

In order to use the R5s, we need to customize the device tree. We do this with a custom Yocto layer.

Add the following line to conf/bblayers.conf:

    /<path to repo>/sources/core/../meta-user \

Then:
    
   $ cd /<path to repo>/sources
   $ git clone https://github.com/edmooring/meta-user

# Building the image

In the build directory (<path to repo>/build):

   $ bitbake openamp-image-minimal

Quite some time later, there will be an image in

tmp/deploy/images/zcu102-zynqmp/openamp-image-minimal-zcu102-zynqmp.wic.qemu-sd

This image can then be moved to where it can be reached via wget for the QEMU docker container.
