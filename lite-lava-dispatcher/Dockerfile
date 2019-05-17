ARG DC_DISPATCHER_IMAGE

FROM ${DC_DISPATCHER_IMAGE}

ENV JLINK_DEB="JLink_Linux_V644h_x86_64.deb"
ENV JLINK_URL="https://www.segger.com/downloads/jlink/${JLINK_DEB}"
ENV ZEPHYR_SDK="zephyr-sdk-0.10.0-pr-77-setup.run"
ENV ZEPHYR_SDK_URL="https://builds.zephyrproject.org/zephyrproject-rtos/sdk-ng/77/${ZEPHYR_SDK}"

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
	python3-pip libusb-1.0.0 vim && \
	apt-get -y -t stretch-backports install libudev1 && \
	pip3 install --upgrade setuptools && \
	pip3 install pyOCD && \
	wget --post-data="accept_license_agreement=accepted&non_emb_ctr=confirmed&submit=Download+software" ${JLINK_URL} -O ${JLINK_DEB} && \
	dpkg -i ${JLINK_DEB} && \
	rm ${JLINK_DEB} && \
	ln -s /opt/SEGGER/JLink/JLinkExe /usr/local/bin && \
	wget ${ZEPHYR_SDK_URL} -O ${ZEPHYR_SDK} && \
	chmod a+x ${ZEPHYR_SDK} && \
	./${ZEPHYR_SDK} --noexec --keep && \
	./toolchains/zephyr-sdk-x86_64-hosttools-standalone-0.9.sh -d /opt/zephyr-sdk -y && \
	rm ${ZEPHYR_SDK} && rm -r toolchains && \
	ln -s /opt/zephyr-sdk/sysroots/x86_64-pokysdk-linux/usr/bin/openocd /usr/local/bin/
