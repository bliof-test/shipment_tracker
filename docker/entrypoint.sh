#!/bin/sh -e
exec envconsul-launch \
  -prefix shipment_tracker/config \
  -secret-no-prefix shipment_tracker/secrets \
  "$@"
