FROM debian:stable

# install tftp package
RUN apt-get update
RUN apt-get install -y --no-install-recommends ser2net

ADD ser2net.conf /etc/

CMD echo -n "Starting " && ser2net -v && ser2net -d -c /etc/ser2net.conf -P /var/run/ser2net.pid
