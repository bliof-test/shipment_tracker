# frozen_string_literal: true
require 'events/base_event'

module Events
  class DeployEvent < Events::BaseEvent
    ENVIRONMENTS = %w(uat staging production).freeze

    def app_name
      if deployed_to_heroku?
        details['app']&.downcase
      else
        details['app_name']&.downcase
      end
    end

    def server
      servers.first
    end

    def version
      if deployed_to_heroku?
        details['head_long']
      else
        details['version']
      end
    end

    def deployed_by
      if deployed_to_heroku?
        details['user']
      else
        details['deployed_by']
      end
    end

    def environment
      if deployed_to_heroku?
        heroku_environment
      else
        details['environment']&.downcase
      end
    end

    def locale
      if deployed_to_heroku?
        heroku_locale || ShipmentTracker::DEFAULT_HEROKU_DEPLOY_LOCALE
      else
        details.fetch('locale', ShipmentTracker::DEFAULT_DEPLOY_LOCALE)&.downcase
      end
    end

    private

    def heroku_environment
      app_name_extension if ENVIRONMENTS.include?(app_name_extension)
    end

    def heroku_locale
      app_name_prefix if Rails.configuration.deploy_regions.include?(app_name_prefix)
    end

    def deployed_to_heroku?
      @is_heroku_deploy ||= details.fetch('url', '').split('.')[-2] == 'herokuapp'
    end

    def app_name_extension
      app_name.split('-').last.downcase if app_name
    end

    def app_name_prefix
      app_name.split('-').first.downcase if app_name
    end

    def servers
      details.fetch('servers', servers_fallback)
    end

    def servers_fallback
      if deployed_to_heroku?
        [details['url']]
      else
        [details['server']].compact
      end
    end
  end
end
