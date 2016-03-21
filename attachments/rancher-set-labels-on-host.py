#!/usr/bin/env python

# e.g. (assumes the rancher creds are also set in env)
# RANCHER_HOST_LABELS="fruit=apple,vegetable=carrot" RANCHER_HOST_NAME=foo.bar.suf rancher-set-labels-on-host.py

import os, sys
import cattle
import requests
import socket
import time

RANCHER_API_VERSION = 1

print('Set labels on a Rancher host:')

print('RANCHER_URL='+os.environ['RANCHER_URL'] + '/v' + str(RANCHER_API_VERSION))
client = cattle.Client(url=os.environ['RANCHER_URL'] + '/v' + str(RANCHER_API_VERSION),
                       access_key=os.environ['RANCHER_ACCESS_KEY'],
                       secret_key=os.environ['RANCHER_SECRET_KEY'])

if os.environ.get('RANCHER_HOST_NAME'):
    hostname = os.environ['RANCHER_HOST_NAME']
else:
    hostname = socket.gethostname()
    os.environ['RANCHER_HOST_NAME'] = hostname

print('RANCHER_HOST_NAME={0}'.format(os.environ['RANCHER_HOST_NAME']))

# it's possible the host was just recently added, so a race condition will
# exist as it can take a couple of minutes to become available
timeout_minutes = 10        # todo: make env var for parameterisation
timeout = time.time() + 60*timeout_minutes
while True:
    host = client.list_host(name=hostname, state='active')

    if len(host) == 0:
        print('Rancher host \'%s\' does not exist yet, try again in 10 seconds.' % hostname)
    else:
        print('Found Rancher host, {0}'.format(host[0]['physicalHostId']))
        break
    if time.time() > timeout:
        print('Rancher host not found active after %s minute(s), giving up!' % str(timeout_minutes))
        sys.exit(1)
    time.sleep(10)

print('Current labels: %s' % host[0]['labels'])

# a dict of labels that will be saved back to the host
labels = {}

# add existing labels
for k, v in host[0]['labels'].iteritems():
    labels[k] = v

# add in new labels
for l in os.environ['RANCHER_HOST_LABELS'].split(','):
    labels[l.split('=')[0]] = l.split('=')[1]

print('Saving labels: {0}'.format(labels))

# finally, get the individual host and update it's labels
h = client.by_id_host(host[0]['physicalHostId'])
client.update(h, labels=labels)
