**General Docker image for executing headless Google Chrome or Firefox Protractor tests cases with TypeScript. The created image does not contain any test code or project. This is the environment for running test cases.**

# To run your test cases in this image
1. Install and set up your [Docker](https://docs.docker.com/engine/installation/) environment 
2. Pull the `zekker6/protractor-headless` image from [DockerHub](https://hub.docker.com/r/zekker6/protractor-headless/)
3. If you have any environment variable which is used for your test project, provide here [environment file](support/testenv).
4. You can see an example for execute your protractor tests in this Docker container at [Makefile](Makefile):
    ```
        docker run -it \
           --privileged \
           --rm \
           --net=host \
           --name cloud-e2e-runner \
           -v $(PWD):/protractor/project \
           zekker6/protractor-headless yarn test
    ```
   >`$(PWD)` or `pwd` the root folder of your Protractor test project. The use of **PWD is optional**, you do not need to navigate to the Protractor test project root. If it is the case, you should add the full path of the root folder instead of the `$(PWD)`.

# Advanced options and information

## --privileged
Chrome uses sandboxing, therefore if you try and run Chrome within a non-privileged container you will receive the following message:

> "Failed to move to new namespace: PID namespaces supported, Network namespace supported, but failed: errno = Operation not permitted".

The `--privileged` flag gives the container almost the same privileges to the host machine resources as other processes running outside the container, which is required for the sandboxing to run smoothly.

Note: chrome now will not run under root user into container, so either add user in docker or use the following in protractor config:

```js
exports.config = {
  ...
  capabilities: {
    browserName: 'chrome',
    chromeOptions: {
      args: ['--no-sandbox']
    }
  },
};

```

<sub>Based on the [Webnicer project](https://hub.docker.com/r/webnicer/protractor-headless/).</sub>

## Run tests in CI   
As you can see [here](scripts/e2e-gui-test.sh) the project contains a predefined bash script to automate launch and test environment setup before tests execution.

Here is the main part:
```sh   
   export TEST_CONTAINER_NAME=cloud-e2e-runner
   
   BASE_URL_RESPONSE=$(curl -k --write-out %{http_code} --silent --output /dev/null $BASE_URL/sl)
   echo $BASE_URL " HTTP status code is: " $BASE_URL_RESPONSE
   if [[ $BASE_URL_RESPONSE -ne 200 ]]; then
       echo $BASE_URL " Web GUI is not accessible!"
       RESULT=1
   else
       docker run -i \
           --privileged \
           --rm \
           --name $TEST_CONTAINER_NAME \
           --net=host \
           -v $(pwd):/protractor/project \
           -v /dev/shm:/dev/shm \
           zekker6/protractor-headless yarn test
           RESULT=$?
   fi
   exit $RESULT
```

## Makefile
We created a very simple [Makefile](Makefile) to be able build and run easily our Docker image on your local machine:
```
make build
```
then
```
make run
```
or you can run the above commands in one round:
```
make all
```
The rules are same as in case of [To run your test cases in this image](#to-run-your-test-cases-in-this-image).

## In-memory File System /dev/shm (Linux only)
Docker has hardcoded value of 64MB for `/dev/shm`. Error can be occurred, because of [page crash](https://bugs.chromium.org/p/chromedriver/issues/detail?id=1097) on memory intensive pages. The easiest way to mitigate the problem is share `/dev/shm` with the host.
```
docker run -it --rm --name protractor-runner --env-file utils/testenv -v /dev/shm:/dev/shm -v $(PWD):/protractor/project sequenceiq/protractor-runner
```
The size of `/dev/shm` in the Docker container can be changed when container is made with [option](https://github.com/docker/docker/issues/2606) `--shm-size`.

For Mac OSX users [this conversation](http://unix.stackexchange.com/questions/151984/how-do-you-move-files-into-the-in-memory-file-system-mounted-at-dev-shm) can be useful.

<sub>Based on the [Webnicer project](https://hub.docker.com/r/webnicer/protractor-headless/).</sub>

## --net=host
This options is required only if the dockerised Protractor is run against localhost on the host.

**Imagine this scenario:**
Run an http test server on your local machine, let's say on port 8000. You type in your browser http://localhost:8000 and everything goes smoothly. Then you want to run the dockerised Protractor against the same localhost:8000. If you don't use `--net=host` the container will receive the bridged interface and its own loopback and so the localhost within the container will refer to the container itself. Using `--net=host` you allow the container to share host's network stack and properly refer to the host when Protractor is run against localhost.

<sub>Based on the [Webnicer project](https://hub.docker.com/r/webnicer/protractor-headless/).</sub>