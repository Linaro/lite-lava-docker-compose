# Host address on which LAVA is accessible.
LAVA_HOST = localhost
# LAVA user to create/use.
LAVA_USER = admin
# lavacli "identity" (cached credential name) for the above user, to submit jobs
# "dispatcher" is legacy name from the original instructions.
LAVA_IDENTITY = dispatcher


# sudo echo below is guaranteedly get a sudo password prompt and provide input
# (may be problematic in 2nd command with "&").
all:
	sudo echo
	sudo contrib/udev-forward.py -i lava-dispatcher &
	docker-compose up

stop:
	-sudo pkill udev-forward.py
	docker-compose stop

clean:
	-sudo pkill udev-forward.py
	docker-compose rm -vsf
	docker volume rm -f lava-server-pgdata lava-server-joboutput lava-server-devices lava-server-health-checks

# Clean host environment to let LAVA setup run w/o issues. As an example,
# stop ModemManager on Ubuntu, which grabs any new serial device and may
# interfere with commnication on it.
clean-env:
	-sudo service apache2 stop
	-sudo service ModemManager stop

# Create various board configs for connected board(s). Supposed to be done
# before "install" target.
board-configs:
	@echo "Note: you should have *all* of your boards connected to USB before running this."
	@echo "Press Ctrl+C to break if not. Review results carefully afterwards."
	@read dummy
	-mv ser2net/ser2net.conf ser2net/ser2net.conf.old
	touch ser2net/ser2net.conf
	@echo
	-mv contrib/LAVA.rules contrib/LAVA.rules.old
	contrib/make-board-files.sh devices

# Make any preparation steps (currently none) and build docker-compose images.
build:
	docker-compose build

install:
	sudo cp contrib/LAVA.rules /etc/udev/rules.d/
	sudo cp contrib/usb-passthrough /usr/local/bin/
	sudo udevadm control --reload

lava-setup: lava-user lava-identity lava-boards

lava-user:
	@echo -n "Input password for LAVA 'admin' user to be created: "; \
	read passwd; \
	test -n "$$passwd" && docker exec -it lava-server lava-server manage users add $(LAVA_USER) --superuser --staff --passwd $$passwd || true
	@echo
	@echo "Now login at http://$(LAVA_HOST)/accounts/login/?next=/api/tokens/ and create an auth token (long sequence of chars)"
	-xdg-open http://$(LAVA_HOST)/accounts/login/?next=/api/tokens/

lava-identity:
	@echo
	@echo -n "Enter auth token: "; \
	read token; \
	test -n "$$token" && lavacli identities add --username $(LAVA_USER) --token $$token --uri http://$(LAVA_HOST)/RPC2 $(LAVA_IDENTITY) || true
	lavacli -i dispatcher system version

lava-boards:
	-lavacli -i $(LAVA_IDENTITY) device-types add frdm-k64f
	-lavacli -i $(LAVA_IDENTITY) devices add --type frdm-k64f --worker lava-dispatcher frdm-k64f-01
	-lavacli -i $(LAVA_IDENTITY) devices dict set frdm-k64f-01 devices/frdm-k64f-01.jinja2
	lavacli -i $(LAVA_IDENTITY) devices tags add frdm-k64f-01 zephyr-net

	-lavacli -i $(LAVA_IDENTITY) device-types add qemu
	-lavacli -i $(LAVA_IDENTITY) devices add --type qemu --worker lava-dispatcher qemu-01
	lavacli -i $(LAVA_IDENTITY) devices dict set qemu-01 devices/qemu-01.jinja2

	-lavacli -i $(LAVA_IDENTITY) devices add --type qemu --worker lava-dispatcher qemu-zephyr-01
	lavacli -i $(LAVA_IDENTITY) devices dict set qemu-zephyr-01 devices/qemu-zephyr-01.jinja2
	lavacli -i $(LAVA_IDENTITY) devices tags add qemu-zephyr-01 qemu-zephyr

	-lavacli -i $(LAVA_IDENTITY) device-types add musca_a
	lavacli -i $(LAVA_IDENTITY) device-types template set musca_a device-types/musca_a.jinja2

	-lavacli -i $(LAVA_IDENTITY) device-types add docker
	-lavacli -i $(LAVA_IDENTITY) devices add --type docker --worker lava-dispatcher docker-01
	lavacli -i $(LAVA_IDENTITY) devices dict set docker-01 devices/docker-01.jinja2
	lavacli -i $(LAVA_IDENTITY) devices tags add docker-01 zephyr-net
	-lavacli -i $(LAVA_IDENTITY) devices add --type docker --worker lava-dispatcher docker-02
	lavacli -i $(LAVA_IDENTITY) devices dict set docker-02 devices/docker-generic.jinja2
	lavacli -i $(LAVA_IDENTITY) devices tags add docker-02 inet

testjob:
	lavacli -i dispatcher jobs submit example/micropython-interactive.job

dispatcher-shell:
	docker exec -it lava-dispatcher bash

server-shell:
	docker exec -it lava-server bash
