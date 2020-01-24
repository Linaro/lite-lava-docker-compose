ARG image=lavasoftware/lava-dispatcher:latest
FROM ${image}

ARG extra_packages=""
RUN apt -q update
RUN DEBIAN_FRONTEND=noninteractive apt-get -q -y install software-properties-common nfs-common
RUN apt-add-repository non-free
RUN apt -q update
RUN DEBIAN_FRONTEND=noninteractive apt-get -q -y install ${extra_packages} net-tools snmp snmp-mibs-downloader
RUN download-mibs

# Add MIBs
RUN mkdir -p /usr/share/snmp/mibs/
ADD https://download.schneider-electric.com/files?p_enDocType=Firmware+-+Released&p_File_Name=powernet428.mib&p_Doc_Ref=APC_PowerNetMIB428 /usr/share/snmp/mibs/powernet428.mib

# Add certificates.
COPY certs/* /etc/lava-dispatcher/certificates.d/

# Add ssh config.
COPY ssh/* /root/.ssh/

# Add power control scripts.
COPY power-control/* /root/power-control/

# Add lab scripts
RUN mkdir -p /usr/local/lab-scripts/
ADD https://git.linaro.org/lava/lava-lab.git/plain/shared/lab-scripts/snmp_pdu_control /usr/local/lab-scripts/
RUN chmod a+x /usr/local/lab-scripts/snmp_pdu_control
ADD https://git.linaro.org/lava/lava-lab.git/plain/shared/lab-scripts/eth008_control /usr/local/lab-scripts/
RUN chmod a+x /usr/local/lab-scripts/eth008_control

ENTRYPOINT ["/root/entrypoint.sh"]
