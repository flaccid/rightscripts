#! /bin/bash -e

#---------------------------------------------------------------------------------------------------------------------------
# Variables
#---------------------------------------------------------------------------------------------------------------------------

: "${RANCHER_HOST_PORT:=8080}"
: "${RANCHER_CONTAINER_PORT:=8080}"
: "${RANCHER_CONTAINER_TIMEZONE:=}"
: "${RANCHER_DOCKER_OPTS:=}"
: "${RANCHER_DOCKER_CMD:=}"
: "${RANCHER_TAG:=stable}"

[ ! -z "$RANCHER_CONTAINER_TIMEZONE" ] && RANCHER_DOCKER_OPTS="$RANCHER_DOCKER_OPTS -e TZ=$RANCHER_CONTAINER_TIMEZONE"

#---------------------------------------------------------------------------------------------------------------------------
# FUNCTIONS
#---------------------------------------------------------------------------------------------------------------------------

function pull_rancher()
{
    sudo docker pull "rancher/server:$RANCHER_TAG"
}

function run_rancher_with_external_db()
{
    sudo docker run $RANCHER_DOCKER_OPTS -d --restart=always -p "$RANCHER_HOST_PORT:$RANCHER_CONTAINER_PORT" \
    -e CATTLE_DB_CATTLE_MYSQL_HOST=$CATTLE_DB_CATTLE_MYSQL_HOST \
    -e CATTLE_DB_CATTLE_MYSQL_PORT=$CATTLE_DB_CATTLE_MYSQL_PORT \
    -e CATTLE_DB_CATTLE_MYSQL_NAME=$CATTLE_DB_CATTLE_MYSQL_NAME \
    -e CATTLE_DB_CATTLE_USERNAME=$CATTLE_DB_CATTLE_USERNAME \
    -e CATTLE_DB_CATTLE_PASSWORD=$CATTLE_DB_CATTLE_PASSWORD \
    "rancher/server:$RANCHER_TAG" "$RANCHER_DOCKER_CMD"
}

function run_rancher_all_in_one()
{
    sudo docker run $RANCHER_DOCKER_OPTS -d --restart=always -p "$RANCHER_HOST_PORT:$RANCHER_CONTAINER_PORT" "rancher/server:$RANCHER_TAG" $RANCHER_DOCKER_CMD
}

function run_rancher()
{
    if [ "$RANCHER_EXTERNAL_DB" = "true" ]; then
        run_rancher_with_external_db
    else
        run_rancher_all_in_one
    fi
}

#---------------------------------------------------------------------------------------------------------------------------
# MAIN
#---------------------------------------------------------------------------------------------------------------------------

# possible race condition with dockerd on boot
sleep 5

if ! sudo docker ps | grep 'rancher/server'; then
  echo 'Running rancher container...'
  set -x
  pull_rancher
  run_rancher
  { set +x; } 2>/dev/null
else
  echo 'rancher/server already running, skipping.'
fi

echo 'Done.'
