#!/usr/bin/env python

import os
import cattle
import requests

RANCHER_API_VERSION = 1

client = cattle.Client(url=os.environ['RANCHER_URL'] + '/v' + str(RANCHER_API_VERSION),
                       access_key=os.environ['RANCHER_ACCESS_KEY'],
                       secret_key=os.environ['RANCHER_SECRET_KEY'])

registration_token = client.list_registrationToken()
registration_url = registration_token[0]['registrationUrl']
registration_file = '/var/spool/rancher/registration.sh'

print('GET: ' + registration_url)
r = requests.get(registration_url)

print('Writing to ' + registration_file)
if not os.path.exists('/var/spool/rancher'):
    os.makedirs('/var/spool/rancher')
f = open(registration_file, 'w')
f.write(r.text)
f.close()

os.chmod(registration_file, 0600)
os.chown(registration_file, 0, 0)
