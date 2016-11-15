#! /bin/bash -e

# Uses by default https://hub.docker.com/_/mysql/

# Inputs:
#
# Used by the script:
# $MYSQL_DOCKER_CONTAINER_NAME
# $MYSQL_DOCKER_IMAGE
# $MYSQL_DOCKER_IMAGE_TAG
# $MYSQL_DOCKER_HOST_PORT
# $MYSQL_DOCKER_ENTRY_SQL
# $MYSQL_DOCKER_VOLUME_MAP
# $MYSQL_DOCKER_MYCNF
# $MYSQL_DOCKER_CONF_D
# $MYSQL_DOCKER_EXTRA_OPTS
# $MYSQL_DOCKER_RESTART_POLICY
#
# Used by the image with environment variables:
# $MYSQL_DATABASE
# $MYSQL_ROOT_PASSWORD
# $MYSQL_USER
# $MYSQL_PASSWORD
# $MYSQL_ALLOW_EMPTY_PASSWORD

: "${MYSQL_DOCKER_CONTAINER_NAME:=mysql}"
: "${MYSQL_DOCKER_IMAGE:=mysql}"
: "${MYSQL_DOCKER_IMAGE_TAG:=latest}"
: "${MYSQL_DOCKER_HOST_PORT:=}"
: "${MYSQL_DOCKER_ENTRY_SQL:=}"
: "${MYSQL_DOCKER_VOLUME_MAP:=}"
: "${MYSQL_DATABASE:=}"
: "${MYSQL_ROOT_PASSWORD:=}"
: "${MYSQL_USER:=}"
: "${MYSQL_PASSWORD:=}"
: "${MYSQL_ALLOW_EMPTY_PASSWORD:=no}"
: "${MYSQL_DOCKER_RESTART_POLICY:=unless-stopped}"

[ ! -z "$MYSQL_DATABASE" ] && createdb="-e MYSQL_DATABASE=$MYSQL_DATABASE"
[ ! -z "$MYSQL_DOCKER_HOST_PORT" ] && ports="-p $MYSQL_DOCKER_HOST_PORT:3306"

[ ! -z "$MYSQL_USER" ] && \
  user="-e MYSQL_USER=$MYSQL_USER -e MYSQL_PASSWORD=$MYSQL_PASSWORD"

[ ! -z "$MYSQL_ALLOW_EMPTY_PASSWORD" ] && \
  emptypass="-e MYSQL_ALLOW_EMPTY_PASSWORD=$MYSQL_ALLOW_EMPTY_PASSWORD"

[ ! -z "$MYSQL_DOCKER_VOLUME_MAP" ] && \
  volumes="-v $MYSQL_DOCKER_VOLUME_MAP"

[ ! -z "$MYSQL_ROOT_PASSWORD" ] && \
  rootpass="-e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD"

if [ ! -z "$MYSQL_DOCKER_ENTRY_SQL" ]; then
  echo "$MYSQL_DOCKER_ENTRY_SQL" > /tmp/entry-sql.sql
  entrysql="-v /tmp/entry-sql.sql:/docker-entrypoint-initdb.d/entry-sql.sql"
fi

if [ ! -z "$MYSQL_DOCKER_MYCNF" ]; then
  sudo mkdir -p /usr/local/etc-docker/mysql
  echo '== my.cnf =='
  echo "$MYSQL_DOCKER_MYCNF" | sudo tee /usr/local/etc-docker/mysql/my.cnf
  echo '===='
  sudo chmod 644 /usr/local/etc-docker/mysql/my.cnf
  volumes="$volumes -v /usr/local/etc-docker/mysql/my.cnf:/etc/mysql/my.cnf"
fi

if [ ! -z "$MYSQL_DOCKER_CONF_D" ]; then
  sudo mkdir -p /usr/local/etc-docker/mysql/conf.d
  echo '== 01-rightscale.cnf =='
  echo "$MYSQL_DOCKER_CONF_D" | sudo tee /usr/local/etc-docker/mysql/conf.d/01-rightscale.cnf
  echo '===='
  sudo chmod 644 /usr/local/etc-docker/mysql/conf.d/01-rightscale.cnf
  volumes="$volumes -v /usr/local/etc-docker/mysql/conf.d/01-rightscale.cnf:/etc/mysql/conf.d/01-rightscale.cnf"
fi

if [ ! -z "$MYSQL_DOCKER_EXTRA_OPTS" ]; then
  extra_opts="$MYSQL_DOCKER_EXTRA_OPTS"
fi

echo 'Running mysql container'
# sudo is being used because new groups are not being picked up with some images

if ! sudo docker ps -a | tail -n +2 | awk -F " " '{print $NF}' | grep "$MYSQL_DOCKER_CONTAINER_NAME" > /dev/null 2>&1; then
  set -x

  container_id=$(sudo -E docker run --restart="$MYSQL_DOCKER_RESTART_POLICY" --name "$MYSQL_DOCKER_CONTAINER_NAME" \
    $ports \
    $user \
    $emptypass \
    $createdb \
    $rootpass \
    $volumes \
    $entrysql \
    -d "$MYSQL_DOCKER_IMAGE":"$MYSQL_DOCKER_IMAGE_TAG" \
      $extra_opts)

    { set +x; } 2>/dev/null
    sleep 5
    echo 'Container log after 5 seconds of runtime:'
    sudo docker logs "$container_id"
else
  echo 'rancher/server already running, skipping.'
fi

echo 'Done.'
