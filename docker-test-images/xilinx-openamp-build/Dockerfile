FROM ubuntu:18.04

# Should match owner of bind mounts on host, the below matches values used
# on Jenkins x86_64-13 build host.
ARG UID=1000
ARG GID=1000
ARG USERNAME=build

# Build happens in this dir.
ENV XILINX_SOURCES=/home/$USERNAME/prj

RUN groupadd -g $GID -o $USERNAME
RUN useradd $USERNAME -u $UID -g $GID -o -m -s /dev/null

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        curl git gpg python python3 \
        build-essential \
        chrpath cpio diffstat gawk texinfo wget \
        locales \
        libidn11 \
        less mc nano iputils-ping && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8

RUN curl -k https://storage.googleapis.com/git-repo-downloads/repo -o repo && \
    chmod a+x repo && mv repo /usr/local/bin/

USER $USERNAME

RUN git config --global user.email "build@local" && \
    git config --global user.name "Automated Build"

RUN mkdir -p $XILINX_SOURCES && cd $XILINX_SOURCES && \
    repo init -u git://github.com/Xilinx/yocto-manifests.git -b rel-v2019.2 </dev/null

RUN cd $XILINX_SOURCES && repo sync

RUN cd $XILINX_SOURCES && bash -c "source setupsdk"

#RUN cd $XILINX_SOURCES && mkdir -p openamp && cd openamp && \
#    git clone https://github.com/OpenAMP/open-amp && \
#    git clone https://github.com/OpenAMP/libmetal && \
#    git clone https://github.com/Xilinx/embeddedsw

COPY local.conf.append $XILINX_SOURCES/build
RUN cd $XILINX_SOURCES/build && cat local.conf.append >> conf/local.conf

COPY skip-FIGETBSZ.patch $XILINX_SOURCES/sources/core/
RUN cd $XILINX_SOURCES/sources/core/ && patch -p1 < skip-FIGETBSZ.patch

RUN cd $XILINX_SOURCES/sources && git clone https://github.com/edmooring/meta-user

RUN cd $XILINX_SOURCES && bash -c "source setupsdk; bitbake-layers add-layer $XILINX_SOURCES/sources/core/../meta-user"

# To build image. Doesn't make sense to put this into image, as it will
# be ~50GB (and take many hours for docker to create).
#RUN cd $XILINX_SOURCES && bash -c "source setupsdk; MACHINE=zcu102-zynqmp bitbake openamp-image-minimal"
