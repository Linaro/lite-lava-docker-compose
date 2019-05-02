ARG image

FROM ${image}

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        ${extra_packages} \
        python3-pip libusb-1.0.0 vim && \
        pip3 install --upgrade setuptools && \
        pip3 install pyOCD
