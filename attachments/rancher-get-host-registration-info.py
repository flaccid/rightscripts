#!/usr/bin/env python

import os
import os.path
import cattle
import requests
import urlparse
from urlparse import urlparse

RANCHER_API_VERSION = 1

# in case user has already provided the api version in the URL or a more specific URL
if '/v' not in os.environ['RANCHER_URL']:
    RANCHER_URL = urlparse.urljoin(os.environ['RANCHER_URL'], '/v' + str(RANCHER_API_VERSION))
else:
    RANCHER_URL = os.environ['RANCHER_URL']

print('RANCHER_URL: ' + RANCHER_URL)
print('RANCHER_ACCESS_KEY: ' + os.environ['RANCHER_ACCESS_KEY'])

client = cattle.Client(url=RANCHER_URL,
                       access_key=os.environ['RANCHER_ACCESS_KEY'],
                       secret_key=os.environ['RANCHER_SECRET_KEY'])

registration_tokens = client.list_registrationToken()

# debug
# print('Registration tokens returned: ' + str(registration_tokens))

# when the URL includes a project ID, get the token for that project
if 'projects' in RANCHER_URL:
    [token for token in registration_tokens if token["accountId"] == os.path.split(urlparse(RANCHER_URL).path)[-1]][0]
else:
    token = registration_tokens[0]

registration_url = token['registrationUrl']
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
