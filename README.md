docker-compose
==============

docker-compose file to setup an instance of **lava-server** and/or **lava-dispatcher**
from scratch. In this setup, every service will be running in a separate container.

Usage
=====

Requirements
------------

In order to use this docker-compose file, you need:

* docker.io
* docker-compose

You can install the dependencies using:

    apt install docker.io docker-compose

Installing
----------

You just need to fetch the sources:

    git clone https://git.lavasoftware.org/lava/pkg/docker-compose
    cd docker-compose

Using it
--------

In order to start the containers, run:

    docker-compose build
    docker-compose up

docker-compose will spawn a container for each services:

* PostgreSQL
* apache2
* gunicorn (aka lava-server-gunicorn)
* lava-master
* lava-logs
* lava-publisher
* lava-dispatcher
* ser2net
* tftpd
* dispatcher-webserver
* ganesha-nfs

All the services will be connected to each other.

docker-compose will also create some volumes for:

* device dictionaries
* health-checks
* job outputs
* PostgreSQL data
* dispatcher httpd
* dispatcher tftpd


Standalone dispatcher container
-------------------------------

## Configuration (simple, for QEMU purposes)

All configuration is stored in `.env` file. Some of the steps are required
whilst others are optional.

* Change DC_LAVA_MASTER_HOSTNAME and DC_LAVA_LOGS_HOSTNAME to <server_name>
  which points to the running LAVA master instance.
* (optional) set DC_LAVA_MASTER_ENCRYPT to `--encrypt` if the master instance
  is using encryption for master-slave communication.
* (optional) [Create certificates](https://validation.linaro.org/static/docs/v2/pipeline-server.html#create-certificates) on the slave.
  `sudo /usr/share/lava-dispatcher/create_certificate.py foo_slave_1`
  This can be done in two ways:
  * by running "docker-compose exec -it docker-compose_lava-dispatcher_1 bash"
  (for this to work you'd need to build and run the containers first - see
  below).
  * alternatively you can create the certificates on system which has LAVA
    packages already installed.
* (optional) Copy public certificate from master and the private slave
  certificate created in previous step to directory `dispatcher/certs/` of this
  project. Currently the key names should be the default ones (master.key and
  slave.key_secret).
* Execute `make lava-dispatcher`; at this point multiple containers should be
  up and running and the worker should connect to the LAVA server instance of
  your choosing.
* Add a new device and set its' device template (alternatively you can update
  existing device to use this new worker)
  Example QEMU device template:
  ```
  {% extends 'qemu.jinja2' %}
  {% set mac_addr = 'DF:AD:BE:EF:33:02' %}
  {% set memory = 1024 %}
  ```
  You can do this via [XMLRPC](https://validation.linaro.org/api/help/#scheduler.devices.set_dictionary), [lavacli](https://docs.lavasoftware.org/lavacli/) or [REST API](https://staging.validation.linaro.org/api/v0.2/devices/staging-qemu01/dictionary/) (if using version 2020.01 and higher).
* (optional) If the lab where this container runs is behind a proxy or you
  require any specific worker environment settings, you will need to update the
  proxy settings by setting the [worker environment](https://docs.lavasoftware.org/lava/proxy.html#using-the-http-proxy)
  You can do this via this [XMLRPC API call](https://validation.linaro.org/api/help/#scheduler.workers.set_env).
  In case the worker sits behind a proxy, you will also need to set
  `SOCKS_PROXY=--socks-proxy <address>:port` in the `.env` configuration file
  Furthermore, you will need to add a proxy settings to the `.env` file for
  docker resource downloads (http_proxy, ftp_proxy and https_proxy environment
  variable).

`Note: If the master instance is behind a firewall, you will need to create a
port forwarding so that ports 5555 and 5556 are open to the public.`


## Configuration (advanced, for physical DUT purposes)

Make sure you went through the basic configuration first, it is mandatory for
this step. In order to run test jobs on physical devices we will need a couple
of additional setup steps:

* PDU control:
  * The dispatcher docker container will already download pdu scripts from
    [lava-lab repo](https://git.linaro.org/lava/lava-lab.git/) which you can use
    in device configuration but if you use custom PDU scripts you need to
    provide them and copy them into `dispatcher/power-control` directory; they
    will be copied into `/root/power-control` path in the container.
  * If you need SSH keys for PDU control, copy the private key to the
    `dispatcher/ssh` directory and the public key on to the PDU
  * SSH config - if there's a need for a specific SSH configuration (like
    tunnel passthrough, proxy, strict host checking, kexalgorithm etc), create
    the config file with relevant settings and copy it into `dispatcher/ssh`
    dir; it will be copied to `/root/.ssh` directory on the dispatcher
    container.
* ser2net config - update `ser2net/ser2net.config` with the corresponding
  serial port and device settings
* Update/add [device dictionary](https://docs.lavasoftware.org/lava/glossary.html#term-device-dictionary) with power commands and connection command
* Add dispatcher_ip setting to the [dispatcher configuration](https://validation.linaro.org/api/help/#scheduler.workers.set_config). Alternatively you can use
[REST API](https://lava_server/api/v0.2/workers/docker_dispatcher_hostname/config/) if you are using version 2020.01 or higher:
  * `dispatcher_ip: <docker host ip address>`
* Disable/stop rpcbind service on host machine if it's running - docker service
  nfs will need port 111 available on the host.


## Running

In order to start the containers, run:

    docker-compose build lava-dispatcher
    docker-compose up lava-dispatcher

or, alternatively:

    make lava-dispatcher