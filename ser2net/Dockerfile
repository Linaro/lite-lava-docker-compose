FROM debian:sid-slim

ENV http_proxy=http://frq07517:pwd@lps5.sgp.st.com:8080
ENV https_proxy=http://frq07517:pwd@lps5.sgp.st.com:8080

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ser2net=3.5-2 && \
    rm -rf /var/lib/apt/lists/*

CMD echo -n "Starting " && ser2net -v && ser2net -d -c /etc/ser2net.conf -P /var/run/ser2net.pid
