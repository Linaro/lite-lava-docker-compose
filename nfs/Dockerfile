FROM debian:stable

RUN apt-get update
RUN apt-get install -y nfs-common nfs-ganesha nfs-ganesha-vfs

ADD start-nfs-ganesha.sh /
ADD ganesha.conf /etc/ganesha/
ADD services /etc/

CMD ["/start-nfs-ganesha.sh"]
