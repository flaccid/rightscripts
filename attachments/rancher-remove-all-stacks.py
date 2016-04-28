#!/usr/bin/env python

import os
import cattle
import requests

RANCHER_API_VERSION = 1

client = cattle.Client(url=os.environ['RANCHER_URL'] + '/v' + str(RANCHER_API_VERSION),
                       access_key=os.environ['RANCHER_ACCESS_KEY'],
                       secret_key=os.environ['RANCHER_SECRET_KEY'])

for stack in client.list_environment():
    print("Deleting stack '%s'" % stack['name'])
    client.delete(stack)
