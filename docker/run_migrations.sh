#!/bin/sh -e
exec docker-entrypoint.sh bundle exec rake --trace db:migrate
