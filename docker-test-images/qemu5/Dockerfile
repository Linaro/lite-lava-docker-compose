FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update

RUN apt-get -y install \
    curl \
    git \
    wget

# Install QEMU (>=4.0 required for AN521 and Cortex-M33)
RUN apt-get -y install \
    qemu-system
