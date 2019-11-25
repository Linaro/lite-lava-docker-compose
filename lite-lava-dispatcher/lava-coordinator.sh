# LAVA Docker startup script for lava-coordinator.
# This should be put in /root/entrypoint.d/ and relies on entrypoint.sh
# processing from official LAVA Docker images.

rm -f /var/run/lava-coordinator.pid
/usr/bin/lava-coordinator --loglevel=DEBUG
