#!/usr/bin/env python

import os, sys
import cattle
import requests
import socket
import time

# expects environment variables:
# RANCHER_URL
# RANCHER_ACCESS_KEY
# RANCHER_SECRET_KEY
# RANCHER_HOST_HOSTNAME (optional, by default uses the hostname script is run on)

RANCHER_API_VERSION = 1

if os.environ.has_key('RANCHER_HOST_HOSTNAME'):
    HOSTNAME = os.environ['RANCHER_HOST_HOSTNAME']
else:
    HOSTNAME = socket.gethostname()

print('Hostname of host being removed: '+HOSTNAME)
print('RANCHER_URL='+os.environ['RANCHER_URL'] + '/v' + str(RANCHER_API_VERSION))

for k in ['http_proxy', 'https_proxy', 'no_proxy']:
    if os.environ.has_key(k):
        print(k+'='+os.environ[k])

try:
    client = cattle.Client(url=os.environ['RANCHER_URL'] + '/v' + str(RANCHER_API_VERSION),
                           access_key=os.environ['RANCHER_ACCESS_KEY'],
                           secret_key=os.environ['RANCHER_SECRET_KEY'])
except ValueError:
    print("I'm sorry Dave.")

print('Finding host...')

# for some reason this doesn't work:
#   hosts = client.list_host(hostname=HOSTNAME)
hosts = client.list_host()
print("%s hosts exist" % str(len(hosts)))

# client side filter
host = [e for e in hosts if e.get('hostname', None) == HOSTNAME]

if len(hosts) > 0:
    print("Found Rancher host '%s' (%s)" % (host[0]['hostname'], host[0]['id']))
    host_id = host[0]['id']
    # print host[0]
else:
    print('No hosts found, assuming already removed, skipping.')
    sys.exit()

print('Initial actions available:')
print(client.by_id_host(host_id).actions)

timeout = time.time() + 60*5   # 5 minutes from now
while client.by_id_host(host_id).state != "purged":
    if 'deactivate' in client.by_id_host(host_id).actions:
        print('Deactivating host...')
        client.by_id_host(host_id).deactivate()
    elif 'remove' in client.by_id_host(host_id).actions:
        print('Removing host...')
        client.by_id_host(host_id).remove()
    elif 'purge' in client.by_id_host(host_id).actions:
        print('Purging host....')
        client.by_id_host(host_id).purge()
    
    time.sleep(3)
    
    print('Current host state is: %s' % client.by_id_host(host_id).state)

    if time.time() > timeout:
        print('Timeout')
        break
