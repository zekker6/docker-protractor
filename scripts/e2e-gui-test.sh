#!/bin/bash -x
# -e  Exit immediately if a command exits with a non-zero status.
# -x  Print commands and their arguments as they are executed.

: ${BASE_URL:? required}
: ${USERNAME:? required}
: ${PASSWORD:? required}
: ${DOCKER_TAG:=2.0}
: ${ENVFILE:=./support/testenv}

export TEST_CONTAINER_NAME=cloud-e2e-runner

image-update() {
    echo "Refresh the Test Runner Docker image"
    docker pull hortonworks/cloudbreak-web-e2e:$DOCKER_TAG
}

image-cleanup() {
    declare desc="Removes all exited containers and old images"

    container-remove-exited

    local all_images=$(docker images | grep "hortonworks/cloudbreak-web-e2e"| sed "s/ \+/ /g"|cut -d' ' -f 1,2|tr ' ' : | tail -n +1)
    local keep_image=hortonworks/cloudbreak-web-e2e:$DOCKER_TAG
    local images_to_delete=$(image-get-old <(echo $all_images) <(echo $keep_image))

    if [ -n "$images_to_delete" ]; then
      echo "Found old/different versioned images: $images_to_delete"
      docker rmi $images_to_delete
    else
      echo "Not found any different versioned images (based on docker-compose.yml). Skip cleanup"
    fi
}

image-get-old() {
    declare desc="Retrieve old images"
    declare all_images="${1:? required: all images}"
    declare keep_images="${2:? required: keep images}"
    local all_imgs=$(cat $all_images) keep_imgs=$(cat $keep_images)

    contentsarray=()
    for versionedImage in $keep_imgs
    do
        image_name="${versionedImage%:*}"
        image_version="${versionedImage#*:}"
        remove_images=$(echo $all_imgs | tr ' ' "\n" | grep "$image_name:" | grep -v "$image_version")

        if [ -n "$remove_images" ]; then
            contentsarray+="${remove_images[@]} "
        fi
    done
    echo ${contentsarray%?}
}

container-remove-exited() {
    declare desc="Remove Exited or Dead containers"
    local exited_containers=$(docker ps -a -f status=exited -f status=dead -q)

    if [[ -n "$exited_containers" ]]; then
        echo "Remove Exited or Dead docker containers"
        docker rm $exited_containers;
    else
        echo "There is no Exited or Dead container"
    fi
}

container-remove-stuck() {
    declare desc="Checking $TEST_CONTAINER_NAME container is running"

    if [[ "$(docker inspect -f {{.State.Running}} $TEST_CONTAINER_NAME 2> /dev/null)" == "true" ]]; then
        echo "Delete the running " $TEST_CONTAINER_NAME " container"
        docker rm -f $TEST_CONTAINER_NAME
    fi
}

test-regression() {
    local base_url_response=$(curl -k --write-out %{http_code} --silent --output /dev/null $BASE_URL/sl)
    echo "$BASE_URL HTTP status code is: $base_url_response"

    if [[ $base_url_response -ne 200 ]]; then
        echo "$BASE_URL Web GUI is not accessible!"
        RESULT=1
    else
        docker run -i \
        --privileged \
        --rm \
        --name $TEST_CONTAINER_NAME \
        --env-file $ENVFILE \
        --net=host \
        -v $(pwd):/protractor/project \
        -v /dev/shm:/dev/shm \
        hortonworks/cloudbreak-web-e2e:$DOCKER_TAG yarn test
        RESULT=$?
    fi
}

container-remove-stuck
image-cleanup
image-update
test-regression

exit $RESULT