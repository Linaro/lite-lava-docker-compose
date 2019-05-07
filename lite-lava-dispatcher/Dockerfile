ARG image

FROM ${image}

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        ${extra_packages} \
        python3-pip libusb-1.0.0 vim && \
        apt-get -y -t stretch-backports install libudev1 && \
        pip3 install --upgrade setuptools && \
        pip3 install pyOCD
