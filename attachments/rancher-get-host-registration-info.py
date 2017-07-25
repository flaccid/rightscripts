#!/usr/bin/env python

import cattle
import os
import os.path
import requests
import time
import urlparse
from requests.auth import HTTPBasicAuth
from urlparse import urljoin
from urlparse import urlparse

PROJECT_ID = None
RANCHER_API_VERSION = 'v2-beta'
DEBUG = False

# create the registration token for the project/environment
# we do this with python-requests because cattle doesn't seem to
# expose a method for creation of a registrationToken
def create_registration_token():
    print('POST: ' + PROJECT_URL + '/registrationtoken')
    r = requests.post(RANCHER_URL + '/registrationtoken',
                  data={'type': 'registrationToken'},
                  auth=HTTPBasicAuth(os.environ['RANCHER_ACCESS_KEY'],
                                     os.environ['RANCHER_SECRET_KEY']))
    time.sleep(2)
    registration_tokens = client.list_registrationToken()

if 'RANCHER_DEBUG' in os.environ and os.environ['RANCHER_DEBUG'] == '1':
    DEBUG = True

# if project is specified (includes api version) split out components
# otherwise construct URL with api version (if needed)
if '/projects/' in os.environ['RANCHER_URL']:
    PROJECT_URL = os.environ['RANCHER_URL']
    print('PROJECT_URL: ' + PROJECT_URL)
    PROJECT_ID = os.path.split(urlparse(os.environ['RANCHER_URL']).path)[-1]
    # reconstruct with api version only
    url_parsed = urlparse(os.environ['RANCHER_URL'])
    api_version = url_parsed.path.split('/')[1]
    proto = url_parsed.scheme
    host = url_parsed.netloc
    RANCHER_URL = '{}://{}/{}'.format(proto, host, api_version)
else:
    if '/v' in os.environ['RANCHER_URL']:
        RANCHER_URL = os.environ['RANCHER_URL']
    else:
        RANCHER_URL = urljoin(os.environ['RANCHER_URL'], '/' + RANCHER_API_VERSION)

print('RANCHER_URL: ' + RANCHER_URL)
print('RANCHER_ACCESS_KEY: ' + os.environ['RANCHER_ACCESS_KEY'])

client = cattle.Client(url=RANCHER_URL,
                       access_key=os.environ['RANCHER_ACCESS_KEY'],
                       secret_key=os.environ['RANCHER_SECRET_KEY'])

registration_tokens = client.list_registrationToken()
found_token = False

# get the token for the specific project, otherwise first returned
if 'PROJECT_ID' in locals() and PROJECT_ID is not None:
    print('PROJECT_ID: ' + PROJECT_ID)
    if DEBUG:
        print('Registration tokens returned: ' + str(registration_tokens))

    for t in registration_tokens:
        if t['accountId'] == PROJECT_ID:
            found_token = True
            token = t

    if not found_token:
        print('No registration token found, creating one')
        create_registration_token()

        for t in registration_tokens:
            if t['accountId'] == PROJECT_ID:
                found_token = True
                token = t
else:
    if len(registration_tokens) == 0:
        print('No registration token found, creating one')
        create_registration_token()

    print('No specific project ID provided, using first returned')
    token = registration_tokens[0]

if DEBUG:
    command = token['command']
    print('registration command: ' + token['command'])

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
