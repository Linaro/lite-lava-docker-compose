docker-compose
==============

docker-compose file to setup an instance of **lava-server** from scratch.
In this setup, every service will be running in a separate container.

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

    docker-compose up

docker-compose will spawn a container for each services:

* PostgreSQL
* apache2
* gunicorn (aka lava-server-gunicorn)
* lava-master
* lava-logs
* lava-publisher

All the services will be connected to each others.

docker-compose will also create some volumes for:

* device dictionaries
* health-checks
* job outputs
* PostgreSQL data
