#! /bin/sh -e

container_id=$(docker ps | grep 'rancher/server' | grep '8080/tcp' | awk -F ' ' '{print $1}')

if [ -z "$container_id" ]; then
  echo 'Rancher server container not found!'
  exit 1
else
  echo "Restarting rancher server container ($container_id)."
  docker restart "$container_id"
fi

echo 'Done.'
