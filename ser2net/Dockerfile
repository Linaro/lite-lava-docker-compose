FROM debian:sid-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ser2net=3.5-2 && \
    rm -rf /var/lib/apt/lists/*

CMD echo -n "Starting " && ser2net -v && ser2net -d -c /etc/ser2net.conf
