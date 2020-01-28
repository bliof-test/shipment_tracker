source 'https://rubygems.org'

gem 'rails', '~> 4.2.11'

gem 'addressable', require: 'addressable/uri'
gem 'bootstrap-sass'
gem 'delayed_job_active_record'
gem 'delayed_job_web'
gem 'dotenv'
gem 'flag-icon-sass'
gem 'git_clone_url'
gem 'haml-rails'
gem 'has_secure_token'
gem 'honeybadger', '< 5'
gem 'jira-ruby', require: 'jira'
gem 'jquery-rails'
gem 'loga'
gem 'newrelic_rpm'
gem 'octokit', '4.14.0', require: false
gem 'omniauth-auth0'
gem 'omniauth'
gem 'pg_failover'
gem 'pg_search'
gem 'pg'
gem 'prometheus_exporter'
gem 'pry-rails'
gem 'rugged', '~> 0.28.1'
gem 'sass-rails'
gem 'slack-notifier'
gem 'solid_use_case'
gem 'uglifier'
gem 'unicorn'
gem 'virtus'

group :dockerignore do
  gem 'therubyracer'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'foreman', require: false
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard-rspec', require: false
  gem 'guard-cucumber', require: false
  gem 'mailcatcher'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'
  gem 'rubocop'
  gem 'pry-byebug'
end

group :production do
  gem 'rails_12factor'
end

group :test do
  gem 'capybara'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'factory_bot'
  gem 'rack-test', require: 'rack/test'
  gem 'shoulda-matchers', require: false
  gem 'simplecov', require: false
  gem 'webmock', require: false
end
