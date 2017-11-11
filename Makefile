ENVFILE=./support/testenv

all:            build run

refresh-image:
				docker pull hortonworks/cloudbreak-web-e2e

run-gui-tests:
				./scripts/e2e-gui-test.sh

build:

				docker build -t hortonworks/cloudbreak-web-e2e .

run:

				docker run -it \
                    --privileged \
                    --rm \
                    --net=host \
                    --name cloud-e2e-runner \
                    --env-file $(ENVFILE) \
                    -v $(PWD):/protractor/project \
                    hortonworks/cloudbreak-web-e2e npm test
                    RESULT=$?

.PHONY:
				all
