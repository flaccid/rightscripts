#! /bin/bash -e

source "$RS_ATTACH_DIR/rs_distro.sh"

if [ "$RS_DISTRO" = 'atomichost' ]; then
  echo 'Red Hat Enterprise Linux Atomic Host not yet supported, but will exit gracefully.'
  exit 0
fi

# PIP is in /usr/local/bin
export PATH=$PATH:/usr/local/bin

if ! type aws >/dev/null 2>&1; then
  if ! type pip >/dev/null 2>&1; then
    if type apt-get >/dev/null 2>&1; then
      sudo apt-get -y update
      sudo apt-get -y install python python-pip
    elif type yum >/dev/null 2>&1; then
      sudo yum -y install python python-pip
    fi
  fi
  sudo pip install awscli
fi

if [ "$AWS_CLI_SETUP_DEFAULT_CONFIG" = 'true' ]; then
  # Get instance region from metadata
  if [ -z "$AWS_CLI_REGION" ]; then
    availability_zone=`curl http://169.254.169.254/latest/meta-data/placement/availability-zone`
    region=${availability_zone%?}
  else
    region="$AWS_CLI_REGION"
  fi

  # Create default config for aws cli
  mkdir -p "$HOME/.aws"

  # default configuration (profiles not yet supported)
  cat <<EOF> "$HOME/.aws/config"
[default]
region = ${region}
output = json
EOF

  # Populate credentials
  if [ ! -z "$AWS_ACCESS_KEY_ID" ]; then
  cat <<EOF> "$HOME/.aws/credentials"
[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF
  fi

  if [ "$AWS_CLI_ROOT_USER_SETUP" = 'true' ]; then
    echo 'copying confg to /root/.aws'
    sudo mkdir -p /root/.aws
    sudo chmod 700 /root/.aws
    sudo cp -v "$HOME/.aws/config" /root/.aws/
    sudo cp -v "$HOME/.aws/credentials" /root/.aws/
  fi
fi

echo 'Done.'
