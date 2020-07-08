all:	build run

refresh-image:
	docker pull zekker6/protractor-headless

build:
	docker build -t zekker6/protractor-headless .

run:
	docker run -it \
		--privileged \
		--rm \
		--net=host \
		--name cloud-e2e-runner \
		-v $(PWD):/protractor/project \
		zekker6/protractor-headless:latest yarn test
	RESULT=$?

check_example:
	docker run -it \
		--privileged \
		--rm \
		--net=host \
		--name cloud-e2e-runner \
		-v $(PWD)/example/project:/protractor/project \
		zekker6/protractor-headless:latest yarn test
	RESULT=$?

.PHONY:
	all
