# Host address on which LAVA is accessible.
LAVA_HOST = localhost
# LAVA user to create/use.
LAVA_USER = admin
# lavacli "identity" (cached credentials name) for the above user,
# to submit jobs, etc.
LAVA_IDENTITY = lava-docker


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
	@echo "Press Ctrl+C to break if not, or Enter to continue. Review results carefully afterwards."
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
	# This dir gets bind-mounted to dispatcher container and sub-containers
	# it runs, to allow access to downloaded images across them.
	sudo mkdir -p /var/lib/lava/dispatcher/tmp/

lava-setup: lava-user lava-identity lava-boards

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

lava-boards:
	# Start with creating "virtual devices", which work in any setup,
	# without additional hardware.

	-lavacli -i $(LAVA_IDENTITY) device-types add qemu
	-lavacli -i $(LAVA_IDENTITY) devices add --type qemu --worker lava-dispatcher qemu-01
	lavacli -i $(LAVA_IDENTITY) devices dict set qemu-01 devices/qemu-01.jinja2

	-lavacli -i $(LAVA_IDENTITY) devices add --type qemu --worker lava-dispatcher qemu-zephyr-01
	lavacli -i $(LAVA_IDENTITY) devices dict set qemu-zephyr-01 devices/qemu-zephyr-01.jinja2
	lavacli -i $(LAVA_IDENTITY) devices tags add qemu-zephyr-01 qemu-zephyr

	-lavacli -i $(LAVA_IDENTITY) device-types add docker
	-lavacli -i $(LAVA_IDENTITY) devices add --type docker --worker lava-dispatcher docker-01
	lavacli -i $(LAVA_IDENTITY) devices dict set docker-01 devices/docker-01.jinja2
	lavacli -i $(LAVA_IDENTITY) devices tags add docker-01 zephyr-net
	-lavacli -i $(LAVA_IDENTITY) devices add --type docker --worker lava-dispatcher docker-02
	lavacli -i $(LAVA_IDENTITY) devices dict set docker-02 devices/docker-generic.jinja2
	lavacli -i $(LAVA_IDENTITY) devices tags add docker-02 inet

	# Now create LAVA device types/device for real hardware boards. Note
	# that these require actual device configuration files for specific
	# boards, which are different from a developer to developer, and
	# thus are not included in the common "lite" branch. You're expected to
	# generate these files locally, and ideally, store in a personal fork
	# of the repository. See the wiki page,
	# https://collaborate.linaro.org/pages/viewpage.action?pageId=118293253#GettingStartedwithLAVA,Docker,andaFRDMK64F:-Capturinglocalboardconfigurationforsemi-automatedsetup
	# for more info.
	# Note that if you run directly from the "lite" branch, the setup will
	# still succeed (because various commands below are prefixed with "-"
	# to make them non-fatal). In this case, you will be able to use
	# virtual devices above, but not hardware boards below.

	-lavacli -i $(LAVA_IDENTITY) device-types add musca_a
	lavacli -i $(LAVA_IDENTITY) device-types template set musca_a device-types/musca_a.jinja2
	# Workaround: device-type template should be on both lava-server and lava-master, but currently
	# ends up only on lava-server after "lavacli device-types template set" above. So, we copy it
	# to lava-master manually.
	# Upstream issue: https://git.lavasoftware.org/lava/pkg/docker-compose/-/issues/4
	docker cp device-types/musca_a.jinja2 lava-master:/etc/lava-server/dispatcher-config/device-types/

	-lavacli -i $(LAVA_IDENTITY) device-types add frdm-k64f
	-lavacli -i $(LAVA_IDENTITY) devices add --type frdm-k64f --worker lava-dispatcher frdm-k64f-01
	-lavacli -i $(LAVA_IDENTITY) devices dict set frdm-k64f-01 devices/frdm-k64f-01.jinja2
	lavacli -i $(LAVA_IDENTITY) devices tags add frdm-k64f-01 zephyr-net

	-lavacli -i $(LAVA_IDENTITY) device-types add cc3220SF
	-lavacli -i $(LAVA_IDENTITY) devices add --type cc3220SF --worker lava-dispatcher cc3220SF-01
	-lavacli -i $(LAVA_IDENTITY) devices dict set cc3220SF-01 devices/cc3220SF-01.jinja2
	lavacli -i $(LAVA_IDENTITY) devices tags add cc3220SF-01 zephyr-net

	-lavacli -i $(LAVA_IDENTITY) device-types add cc13x2-launchpad
	-lavacli -i $(LAVA_IDENTITY) devices add --type cc13x2-launchpad --worker lava-dispatcher cc13x2-launchpad-01
	-lavacli -i $(LAVA_IDENTITY) devices dict set cc13x2-launchpad-01 devices/cc13x2-launchpad-01.jinja2
	lavacli -i $(LAVA_IDENTITY) devices tags add cc13x2-launchpad-01 zephyr-net

	-lavacli -i $(LAVA_IDENTITY) device-types add disco-l475-iot1
	-lavacli -i $(LAVA_IDENTITY) devices add --type disco-l475-iot1 --worker lava-dispatcher disco-l475-iot1-01
	-lavacli -i $(LAVA_IDENTITY) devices dict set disco-l475-iot1-01 devices/disco-l475-iot1-01.jinja2
	lavacli -i $(LAVA_IDENTITY) devices tags add disco-l475-iot1-01 zephyr-net

testjob:
	lavacli -i $(LAVA_IDENTITY) jobs submit example/micropython-interactive.job

dispatcher-shell:
	docker exec -it lava-dispatcher bash

server-shell:
	docker exec -it lava-server bash
