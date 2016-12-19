#!/bin/bash

: ${SHELL_CMD:=}

[ -z "$SHELL_CMD" ] && echo '$SHELL_CMD not set, exiting.' && exit 1

echo "cmd: $SHELL_CMD"
eval "$SHELL_CMD" >out 2>err; exit=$?; out=$(<out) err=$(<err); rm out err

echo "exited: $exit"
echo '==out=='
echo "$out"
echo '======='

if [ "$exit" -ne 0 ]; then
  echo '==stderr=='
  echo "$err"
  echo '=========='
  exit 1
fi

echo 'Done.'
