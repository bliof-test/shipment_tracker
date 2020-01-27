background: bundle exec rake jobs:work
git_worker: bundle exec rake jobs:update_git_loop
mailcatcher: mailcatcher -f
prometheus_exporter: bundle exec prometheus_exporter
web: bundle exec rails server --port $PORT
worker: bundle exec rake jobs:update_events_loop
