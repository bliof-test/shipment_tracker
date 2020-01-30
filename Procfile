background:          env PROMETHEUS_EXPORTER_HOST=localhost PROMETHEUS_EXPORTER_PORT=9394 bundle exec rake jobs:work
git_worker:          env PROMETHEUS_EXPORTER_HOST=localhost PROMETHEUS_EXPORTER_PORT=9394 bundle exec rake jobs:update_git_loop
mailcatcher:         env PROMETHEUS_EXPORTER_HOST=localhost PROMETHEUS_EXPORTER_PORT=9394 mailcatcher -f
prometheus_exporter: env PROMETHEUS_EXPORTER_HOST=localhost PROMETHEUS_EXPORTER_PORT=9394 bundle exec prometheus_exporter
web:                 env PROMETHEUS_EXPORTER_HOST=localhost PROMETHEUS_EXPORTER_PORT=9394 bundle exec rails server --port $PORT
worker:              env PROMETHEUS_EXPORTER_HOST=localhost PROMETHEUS_EXPORTER_PORT=9394 bundle exec rake jobs:update_events_loop
