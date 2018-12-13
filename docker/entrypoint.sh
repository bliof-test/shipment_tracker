#!/bin/sh -e
exec envconsul-launch -prefix shipment_tracker/config \
                          "$@"
