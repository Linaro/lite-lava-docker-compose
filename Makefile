# Host address on which LAVA is accessible.
LAVA_HOST = localhost
# LAVA user to create/use.
LAVA_USER = admin
# lavacli "identity" (cached credentials name) for the above user,
# to submit jobs, etc.
LAVA_IDENTITY = lava-docker


all:
	docker-compose build
	docker-compose up

lava-dispatcher:
	docker-compose build lava-dispatcher
	docker-compose up lava-dispatcher

clean:
	docker-compose rm -vsf
	docker volume rm -f lava-server-pgdata lava-server-joboutput lava-server-device-types lava-server-devices lava-server-health-checks lava-server-worker-state lava-server-worker-http lava-server-worker-tftp

# Make any preparation steps (currently none) and build docker-compose images.
build:
	docker-compose build

install:
	sudo cp contrib/LAVA.rules /etc/udev/rules.d/
	sudo cp contrib/usb-passthrough /usr/local/bin/
	sudo udevadm control --reload

lava-setup: lava-user lava-identity

lava-user:
	@echo -n "Input password for the LAVA 'admin' user to be created: "; \
	read passwd; \
	test -n "$$passwd" && docker-compose exec lava-server lava-server manage users add $(LAVA_USER) --superuser --staff --passwd $$passwd || true
	@echo
	@echo "Now login with username: admin, passwd: (entered above) at:"
	@echo "http://$(LAVA_HOST)/accounts/login/?next=/api/tokens/"
	@echo "and create an auth token (long sequence of chars)."
	@echo "(Trying to open this link in browser for you.)"
	-xdg-open http://$(LAVA_HOST)/accounts/login/?next=/api/tokens/

lava-identity:
	@echo
	@echo -n "Enter the auth token that you created: "; \
	read token; \
	test -n "$$token" && lavacli identities add --username $(LAVA_USER) --token $$token --uri http://$(LAVA_HOST)/RPC2 $(LAVA_IDENTITY) || true
	lavacli -i $(LAVA_IDENTITY) system version

.PHONY: all dispatcher clean
