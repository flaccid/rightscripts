#!/usr/bin/env python

# e.g. (assumes the rancher creds are also set in env)
# RANCHER_HOST_LABELS="fruit=apple,vegetable=carrot" RANCHER_HOST_NAME=foo.bar.suf rancher-set-labels-on-host.py

import argparse
import os, sys
import cattle
import requests
import socket
import time

RANCHER_API_VERSION = 1


def main():
  parser = argparse.ArgumentParser(description='Set labels on a Rancher host')
  parser.add_argument('--host',        type=str, default=socket.gethostname(), help='Rancher host to set labels for')
  parser.add_argument('--url',         type=str, required=True, help='Rancher url to use')
  parser.add_argument('--accesskey',   type=str, required=True, help='Rancher API Key to use')
  parser.add_argument('--secretkey',   type=str, required=True, help='Rancher API Secret Key to use')
  parser.add_argument('--label',       type=str, required=True, action='append', help='Label to set e.g: --label foo=bar this ')
  parser.add_argument('--env',         type=str, default=None, help='Rancher environment to use')
  parser.add_argument('--timeout',     type=str, default=600, help='Timeout in seconds to wait for host to be active. default 600 seconds')
  parser.add_argument('--retry',       type=str, default=10, help='retry time in seconds waiting for a host to be active. default 10 seconds')
  parser.add_argument('--cleanmissing',type=bool, default=False, help='this will remove labels on a host that are not supplied with the --label argument. defaults to false')
  #parser.add_argument('--env',       type=str, default=None, help='Rancher environment to use')

  args = parser.parse_args()


  # When only a single --label passed we get a string else a list
  if isinstance(args.label, basestring): 
    labels = [args.label]
  else:
    labels = args.label

  print('Setting labels on a Rancher host:')

  rancher_full_url = '{}/v{}'.format(args.url, str(RANCHER_API_VERSION))
  print 'RANCHER_URL: {}'.format(rancher_full_url)

  client = cattle.Client(
    url=rancher_full_url,
    access_key=args.accesskey,
    secret_key=args.secretkey,
  )

  print 'RANCHER_HOST_NAME: {}'.format(args.host)

  epoch = time.time() + args.timeout
  cattle_host = wait_host_active(client, args.host, epoch, args.timeout, args.retry)


  # a dict of labels that will be saved back to the host
  cur_labels = cattle_host[0]['labels']

  print 'Current labels: {}'.format(cur_labels)

  # Generate dict with supplied labels
  new_labels = {}
  for l in labels:
    (k,v) = l.split('=', 2)
    new_labels[k] = unicode(v)

  changed = False
  for i in new_labels:
    if i in cur_labels:
      if v != cur_labels[i]:
        print 'INFO: {} has a changed value from: {} to: {}'.format(i, cur_labels[i], v)
        changed = True
    else:
      print 'INFO: {} is a new label'.format(i)
      change = True
      
  for k,v in cur_labels.iteritems():
    if args.cleanmissing:
      print "Removing old labels not defined"
      change = True
    else:
      if k not in new_labels:
        new_labels[k] = v

  print 'Saving labels: {}'.format(new_labels)
  # finally, get the individual host and update it's labels
  if changed:
    h = client.by_id_host(cattle_host[0]['physicalHostId'])
    client.update(h, labels=new_labels)
  else:
    print "Nothing has changed...skipping update"

def wait_host_active(c, host, epoch, timeout, retry):

  while True:
    h = c.list_host(hostname=host, state='active')

    if len(h) == 0:
        print 'Rancher host \'{}\' does not exist yet, try again in 10 seconds.'.format(host)
    else:
        print 'Found Rancher host: {}'.format(h[0]['physicalHostId'])
        return h
    if time.time() > epoch:
        print 'Rancher host not found active after {} second(s), giving up!'.format(str(timeout))
        sys.exit(1)

    time.sleep(retry)

if __name__ == "__main__":
  main()
