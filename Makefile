ENVFILE=./support/testenv

refresh-image:
				docker pull hortonworks/docker-e2e-cloud

run-gui-tests:
				./scripts/e2e-gui-test.sh

build:

				docker build -t hortonworks/docker-e2e-cloud .

run:

				docker run -it \
                    --privileged \
                    --rm \
                    --net=host \
                    --name cloud-e2e-runner \
                    --env-file $(ENVFILE) \
                    -v $(PWD):/protractor/project \
                    hortonworks/docker-e2e-cloud npm test
                    RESULT=$?

.PHONY:
				run
