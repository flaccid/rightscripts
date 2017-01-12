#!/bin/sh -e

echo '=== docker containers ==='
sudo docker ps
echo '==='
echo
echo '=== docker images ==='
sudo docker images
echo '==='

echo 'Done.'
