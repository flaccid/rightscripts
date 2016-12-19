#! /bin/sh -e

container_id=$(sudo docker ps | grep 'rancher/server' | grep '8080/tcp' | awk -F ' ' '{print $1}')

if [ -z "$container_id" ]; then
  echo 'Rancher server container not found!'
  exit 1
else
  echo "Restarting rancher server container ($container_id)."
  if sudo docker restart "$container_id"; then
    slack_message="$(hostname -f) rancher container ($container_id) restart complete."
    success=1
  else
    slack_message="$(hostname -f) rancher container ($container_id) restart failed!"
    success=0
  fi
fi

if [ "$RANCHER_RESTART_NOTIFY_SLACK" = 'true' ]; then
  echo 'Notifying Slack...'

  no_proxy="$(echo $RANCHER_RESTART_SLACK_WEBHOOK_URL | awk -F/ '{print $3}')"
  export no_proxy
  data="{\"text\": \"$slack_message\", \"channel\": \"$RANCHER_RESTART_SLACK_CHANNEL\", \"username\": \"$RANCHER_RESTART_SLACK_USERNAME\", \"icon_emoji\": \"$RANCHER_RESTART_SLACK_ICON_EMOJI\"}"

  curl -v -X POST -H 'Content-type: application/json' --data "$data" $RANCHER_RESTART_SLACK_WEBHOOK_URL
fi

if [ "$success" -eq 1 ]; then
  echo 'Rancher server container restart succeeded!'
  exit 0
else
  echo 'Rancher server container restart failed!'
  exit 1
fi
