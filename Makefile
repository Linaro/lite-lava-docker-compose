# Host address on which LAVA is accessible.
LAVA_HOST = localhost
# LAVA user to create/use.
LAVA_USER = admin
# lavacli "identity" (cached credential name) for the above user, to submit jobs
# "dispatcher" is legacy name from the original instructions.
LAVA_IDENTITY = dispatcher


all:
	sudo contrib/udev-forward.py -i lava-dispatcher &
	docker-compose up

stop:
	-sudo pkill udev-forward.py
	docker-compose stop

clean:
	-sudo pkill udev-forward.py
	docker-compose rm -vsf
	docker volume rm -f lava-server-pgdata lava-server-joboutput lava-server-devices lava-server-health-checks

install:
	sudo cp contrib/LAVA.rules /etc/udev/rules.d/
	sudo cp contrib/usb-passthrough /usr/local/bin/
	sudo udevadm control --reload

lava-setup: lava-user lava-identity lava-boards

lava-user:
	@echo -n "Input LAVA admin user passwd: "; \
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
	lavacli -i $(LAVA_IDENTITY) devices dict set frdm-k64f-01 devices/frdm-k64f-01.jinja2
	-lavacli -i $(LAVA_IDENTITY) device-types add qemu
	-lavacli -i $(LAVA_IDENTITY) devices add --type qemu --worker lava-dispatcher qemu-01
	lavacli -i $(LAVA_IDENTITY) devices dict set qemu-01 devices/qemu-01.jinja2

testjob:
	lavacli -i dispatcher jobs submit example/lava.job
