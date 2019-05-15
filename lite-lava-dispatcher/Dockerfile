ARG image

FROM ${image}

ENV JLINK_DEB="JLink_Linux_V644h_x86_64.deb"
ENV JLINK_URL="https://www.segger.com/downloads/jlink/${JLINK_DEB}"

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        ${extra_packages} \
        python3-pip libusb-1.0.0 vim && \
        apt-get -y -t stretch-backports install libudev1 && \
        pip3 install --upgrade setuptools && \
        pip3 install pyOCD && \
        wget --post-data="accept_license_agreement=accepted&non_emb_ctr=confirmed&submit=Download+software" ${JLINK_URL} -O ${JLINK_DEB} && \
        dpkg -i ${JLINK_DEB} && \
        rm ${JLINK_DEB} && \
        ln -s /opt/SEGGER/JLink/JLinkExe /usr/local/bin
