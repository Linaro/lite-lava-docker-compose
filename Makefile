# Host address on which LAVA is accessible.
LAVA_HOST = localhost
# LAVA user to create/use.
LAVA_USER = admin
# lavacli "identity" (cached credential name) for the above user, to submit jobs
# "dispatcher" is legacy name from the original instructions.
LAVA_IDENTITY = dispatcher


all:
	docker-compose up

clean:
	docker-compose rm -vsf
	docker volume rm -f lava-server-pgdata lava-server-joboutput lava-server-devices lava-server-health-checks

install:
	sudo cp contrib/LAVA.rules /etc/udev/rules.d/
	sudo cp contrib/usb-passthrough /usr/local/bin/
	sudo udevadm control --reload

lava-setup: lava-user lava-identity

lava-user:
	@echo -n "Input LAVA admin user passwd: "; \
	read passwd; \
	test -n "$$passwd" && docker exec -it lava-server lava-server manage users add $(LAVA_USER) --superuser --staff --passwd $$passwd || true
	@echo
	@echo "Now login at http://$(LAVA_HOST)/accounts/login/?next=/api/tokens/ and create an auth token (long sequence of chars)"

lava-identity:
	@echo
	@echo -n "Enter auth token: "; \
	read token; \
	test -n "$$token" && lavacli identities add --username $(LAVA_USER) --token $$token --uri http://$(LAVA_HOST)/RPC2 $(LAVA_IDENTITY) || true
	lavacli -i dispatcher system version
