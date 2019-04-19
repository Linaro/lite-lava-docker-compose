all:
	docker-compose up

clean:
	docker-compose rm -vsf
	docker volume rm -f lava-server-pgdata lava-server-joboutput lava-server-devices lava-server-health-checks
