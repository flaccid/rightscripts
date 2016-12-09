#!/bin/sh -x

# no checking/idempotency yet!

! ip addr | grep lxcbr0 && echo 'lxcbr0 not active, skipping.' && exit 0

sudo ip route del 10.0.3.0/24
sudo ifconfig lxcbr0 down
sudo brctl delbr lxcbr0

echo 'Done.'
