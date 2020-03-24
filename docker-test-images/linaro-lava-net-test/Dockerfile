FROM ubuntu:18.04

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get -y install \
	    apache2-utils \
	    curl \
	    git \
	    iproute2 \
	    iputils-ping \
	    net-tools \
	    python3 \
	    wget \
	&& rm -rf /var/lib/apt/lists/*
