#! /bin/bash -e

: "${INSTALL_DOCKER_CA_CERT:=true}"
: "${DOCKER_CA_CERT_CN:=}"
: "${DOCKER_CA_CERT_MATERIAL:=}"

if [ "$INSTALL_DOCKER_CA_CERT" != 'true' ]; then
  echo '$INSTALL_DOCKER_CA_CERT not set to true, skipping.'
  exit 0
fi

sudo mkdir -pv "/etc/docker/certs.d/$DOCKER_CA_CERT_CN"

echo "Installing cert to /etc/docker/certs.d/$DOCKER_CA_CERT_CN"
echo "$DOCKER_CA_CERT_MATERIAL" | sudo tee "/etc/docker/certs.d/$DOCKER_CA_CERT_CN/ca.crt"

echo 'Done.'
