all:
	docker-compose build
	docker-compose up

lava-dispatcher:
	docker-compose build lava-dispatcher
	docker-compose up lava-dispatcher

clean:
	docker-compose rm -vsf
	docker volume rm -f lava-server-pgdata lava-server-joboutput lava-server-device-types lava-server-devices lava-server-health-checks lava-server-worker-state lava-server-worker-http lava-server-worker-tftp

.PHONY: all dispatcher clean
