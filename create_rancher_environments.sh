#!/bin/sh -e

# $RANCHER_ENVIRONMENTS_CREATE
# $RANCHER_URL
# $RANCHER_ACCESS_KEY
# $RANCHER_SECRET_KEY

if [ -z "$RANCHER_ENVIRONMENTS_CREATE" ]; then
  echo '$RANCHER_ENVIRONMENTS_CREATE not set, skipping.'
  exit 0
fi

envs=(${RANCHER_ENVIRONMENTS_CREATE//,/ })

# find rancher server

for env in "${envs[@]}"
do
  # check if environment exists
  if ! rancher environment ls | awk -F ' ' '{print $2}' | grep -q "$env"; then
    env_id=$(rancher environment create "$env")
    echo "Environment, '$env' ($env_id) successfully created."
  else
    echo "Environment, '$env' already exists, skipping creation."
  fi
done

echo 'Done.'
