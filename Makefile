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

	-lavacli -i $(LAVA_IDENTITY) device-types add frdm-k64f
	-lavacli -i $(LAVA_IDENTITY) devices add --type frdm-k64f --worker lava-dispatcher frdm-k64f-01
	-lavacli -i $(LAVA_IDENTITY) devices dict set frdm-k64f-01 devices/frdm-k64f-01.jinja2
	lavacli -i $(LAVA_IDENTITY) devices tags add frdm-k64f-01 zephyr-net

.PHONY: all dispatcher clean
