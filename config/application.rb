# frozen_string_literal: true

require File.expand_path('boot', __dir__)

# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_record/railtie'
require 'active_job/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'sprockets/railtie'

# Requires gems listed in Gemfile, including any gems limited to :test, :development, or :production groups.
Bundler.require(*Rails.groups)

module ShipmentTracker
  JIRA_USER ||= ENV.fetch('JIRA_USER', nil)
  JIRA_PASSWD ||= ENV.fetch('JIRA_PASSWD', nil)
  JIRA_FQDN ||= ENV.fetch('JIRA_FQDN', nil)
  JIRA_EXTERNAL_FQDN ||= ENV.fetch('JIRA_EXTERNAL_FQDN', JIRA_FQDN)
  JIRA_PATH ||= ENV.fetch('JIRA_PATH', nil)
  JIRA_USE_SSL ||= ENV.fetch('JIRA_USE_SSL', 'true') == 'true'
  GITHUB_REPO_READ_TOKEN ||= ENV.fetch('GITHUB_REPO_READ_TOKEN', nil)
  GITHUB_REPO_STATUS_WRITE_TOKEN ||= ENV.fetch('GITHUB_REPO_STATUS_WRITE_TOKEN', nil)
  DEFAULT_DEPLOY_LOCALE ||= ENV.fetch('DEFAULT_DEPLOY_LOCALE', 'gb') # For older events without locale
  NUMBER_OF_TICKETS_TO_DISPLAY ||= ENV.fetch('NUMBER_OF_TICKETS_TO_DISPLAY', 100)
  DISABLE_GITHUB_STATUS_UPDATES_FOR_APPS ||=
    ENV.fetch('DISABLE_GITHUB_STATUS_UPDATES_FOR_APPS', '').split(',').map(&:strip)
  # TODO: Move our constants here. Keep Rails config for actual Rails configuration.

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers;
    # all .rb files in that directory are automatically loaded.

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.active_record.schema_format = :sql

    config.action_dispatch.perform_deep_munge = false

    routes.default_url_options = {
      protocol: ENV.fetch('PROTOCOL', 'https'),
      host: ENV.fetch('HOST_NAME', ENV['PORT'] ? "localhost:#{ENV['PORT']}" : 'localhost'),
    }

    config.ssh_private_key = ENV['SSH_PRIVATE_KEY']
    config.ssh_public_key = ENV['SSH_PUBLIC_KEY']
    config.ssh_user = ENV['SSH_USER']
    config.approved_statuses = ENV.fetch('APPROVED_STATUSES', 'Ready for Deployment, Deployed, Done')
                                  .split(/\s*,\s*/)
    config.development_statuses = ENV.fetch('DEVELOPMENT_STATUSES', 'In Progress, In Review')
                                     .split(/\s*,\s*/)
    config.git_repository_cache_dir = ENV.fetch('GIT_REPOSITORY_CACHE_DIR', Dir.tmpdir)
    config.data_maintenance_mode = ENV['DATA_MAINTENANCE'] == 'true'
    config.allow_git_fetch_on_request = ENV['ALLOW_GIT_FETCH_ON_REQUEST'] == 'true'
    config.git_worker_interval_seconds = ENV.fetch('GIT_WORKER_INTERVAL_SECONDS', 5).to_f
    config.git_worker_max_threads = ENV.fetch('GIT_WORKER_MAX_THREADS', 16).to_i
    config.disable_github_status_update = ENV['DISABLE_GITHUB_STATUS_UPDATE'] == 'true'
    config.disable_jira_comments = ENV['DISABLE_JIRA_COMMENTS'] == 'true'

    config.default_deploy_region = ENV.fetch('DEFAULT_DEPLOY_REGION', 'gb')

    # value is 'gb' and not 'uk' to comply with 'ISO 3166-1 alpha-2' codes
    config.deploy_regions = ENV.fetch('DEPLOY_REGIONS', 'gb,us').split(',')

    config.loga = { service_name: 'shipment-tracker' }
    config.log_level = ENV.fetch('LOG_LEVEL', 'info')
  end
end
