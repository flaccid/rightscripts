#!/bin/bash -e

: "${CIRCLECI_INSTALL_OPTS:=no-proxy}"

pushd '/tmp'
  curl -sSL https://get.replicated.com/docker > install.sh
  chmod +x install.sh
  sudo ./install.sh $CIRCLECI_INSTALL_OPTS
popd
