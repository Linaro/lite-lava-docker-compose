FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update

# Workaround for shared-mime-info hanging (== running
# *very* slowly) in postinstall script in docker.
RUN apt-get download shared-mime-info && \
    dpkg --unpack shared-mime-info*.deb && \
    rm -f /var/lib/dpkg/info/shared-mime-info.postinst && \
    apt-get install -y -f

RUN apt-get -y install \
    apache2-utils \
    curl \
    git \
    iproute2 \
    iputils-ping \
    mc \
    net-tools \
    python3 \
    telnet \
    wget

RUN apt-get -y install \
    apache2

# Prepare test file for Zephyr's big_http_download sample.
RUN mkdir -p /var/www/html/static && \
    cd /var/www/html/static && \
    wget http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/current/images/hd-media/vmlinuz

EXPOSE 80
