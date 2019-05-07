ARG DC_DISPATCHER_IMAGE

FROM ${DC_DISPATCHER_IMAGE}

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
	python3-pip libusb-1.0.0 && \
	apt-get -y -t stretch-backports install libudev1 && \
	pip3 install --upgrade setuptools && \
	pip3 install pyOCD
