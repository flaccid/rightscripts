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
: "${RANCHER_CONTAINER_POST_CMDS:=}"
: "${RANCHER_CONTAINER_SSH_PRIV_KEY}"

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
    "rancher/server:$RANCHER_TAG" $RANCHER_DOCKER_CMD
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

function container_id()
{
  local container_id=$(docker inspect --format="{{.Id}}" "$(docker ps | grep 'rancher/server' | awk '{print $NF}')")
  echo "$container_id"
}

# the use of `exec` is not preferrable
# currently a workaround as rightlink as no tty needed for some docker commands

function inject_ssh_priv_key()
{
  echo 'Inject SSH key.'
  local tmpfile="$(mktemp /tmp/rs.XXXXXXXXXX)"
  echo "$RANCHER_CONTAINER_SSH_PRIV_KEY" > "$tmpfile"
  # [[ $- == *i* ]] && echo 'Interactive' || echo 'Not interactive'
  cid="$(container_id)"
  sudo docker exec "$cid" mkdir -p /root/.ssh
  echo "$(exec sudo docker cp $tmpfile $cid:/root/.ssh/id_rsa)"
  sleep 5
  rm -f "$tmpfile"
  sudo docker exec "$cid" chmod 400 /root/.ssh/id_rsa
}

function run_post_cmds()
{
  echo 'Running post commands within container...'
  cid="$(container_id)"
  local tmpfile="$(mktemp /tmp/rs.XXXXXXXXXX)"
  echo '#!/bin/bash -e' > "$tmpfile"
  echo "$RANCHER_CONTAINER_POST_CMDS" >> "$tmpfile"
  echo "$(exec sudo docker cp $tmpfile $cid:/tmp/rancher-post.bash)"
  sudo docker exec "$cid" chmod +x /tmp/rancher-post.bash
  sudo docker exec "$cid" /tmp/rancher-post.bash
  sudo docker exec "$cid" rm /tmp/rancher-post.bash
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

[ ! -z "$RANCHER_CONTAINER_SSH_PRIV_KEY" ] && inject_ssh_priv_key

[ ! -z "$RANCHER_CONTAINER_POST_CMDS" ] && run_post_cmds

echo 'Done.'
