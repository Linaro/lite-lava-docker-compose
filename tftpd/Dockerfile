FROM debian:stable

# install tftp package
RUN apt-get update
RUN apt-get install -y tftpd-hpa

CMD in.tftpd -L --user tftp -a 0.0.0.0:69 -s -B1468 -v /srv/tftp

