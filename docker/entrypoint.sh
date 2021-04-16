#!/bin/sh -e
. /etc/mesos-vault-token

exec envconsul \
  -config /etc/envconsul-common.hcl \
  -config /app/envconsul.hcl \
  "$@"
