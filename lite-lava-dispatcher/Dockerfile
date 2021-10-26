ARG image

FROM ${image}

ENV JLINK_DEB="JLink_Linux_V688a_x86_64.deb"
ENV JLINK_URL="https://www.segger.com/downloads/jlink/${JLINK_DEB}"
ENV ZEPHYR_HOST_TOOLS="zephyr-sdk-x86_64-hosttools-standalone-0.9.sh"
ENV ZEPHYR_HOST_TOOLS_URL="https://builds.zephyrproject.org/sdk/0.11.4/${ZEPHYR_HOST_TOOLS}"

RUN mkdir -p /etc/lava-coordinator
COPY lava-coordinator.conf /etc/lava-coordinator/

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        ${extra_packages} \
        python3-pip libusb-1.0.0 vim wget && \
        apt-get -y install libudev1 && \
        pip3 install --upgrade setuptools && \
        pip3 install -U pyocd==0.29.0 && \
        wget --no-check-certificate --post-data="accept_license_agreement=accepted&non_emb_ctr=confirmed&submit=Download+software" ${JLINK_URL} -O ${JLINK_DEB} && \
        apt-get -y install libncurses5 && \
        dpkg -i ${JLINK_DEB} && \
        rm ${JLINK_DEB} && \
        ln -s /opt/SEGGER/JLink/JLinkExe /usr/local/bin && \
        wget ${ZEPHYR_HOST_TOOLS_URL} -O ${ZEPHYR_HOST_TOOLS} && \
        chmod a+x ${ZEPHYR_HOST_TOOLS} && \
        ./${ZEPHYR_HOST_TOOLS} -d /opt/zephyr-sdk -y && \
        rm ${ZEPHYR_HOST_TOOLS} && \
        ln -s /opt/zephyr-sdk/sysroots/x86_64-pokysdk-linux/usr/bin/openocd /usr/local/bin/ && \
        git clone https://github.com/Yepkit/ykush && \
        cd ykush && ./build.sh && \
        cp bin/ykushcmd /usr/local/bin && \
        cd .. && rm -fr ykush \
