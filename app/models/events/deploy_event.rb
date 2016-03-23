# frozen_string_literal: true
require 'events/base_event'

module Events
  class DeployEvent < Events::BaseEvent
    ENVIRONMENTS = %w(uat staging production).freeze

    def app_name
      if deployed_to_heroku?
        heroku_app_name.chomp("-#{heroku_environment}").downcase
      else
        details['app_name']&.downcase
      end
    end

    def server
      if deployed_to_heroku?
        details['url']
      else
        servers.first
      end
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

    def servers
      details.fetch('servers', [details['server']].compact)
    end

    def deployed_to_heroku?
      @is_heroku_deploy ||= details.fetch('url', '').split('.')[-2] == 'herokuapp'
    end

    def heroku_app_name
      details['app']
    end

    def heroku_environment
      heroku_app_name_extension if ENVIRONMENTS.include?(heroku_app_name_extension)
    end

    def heroku_locale
      heroku_app_name_prefix if Rails.configuration.deploy_regions.include?(heroku_app_name_prefix)
    end

    def heroku_app_name_extension
      heroku_app_name.split('-').last.downcase
    end

    def heroku_app_name_prefix
      heroku_app_name.split('-').first.downcase
    end
  end
end
