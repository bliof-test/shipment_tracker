# frozen_string_literal: true
require 'events/base_event'

module Events
  class DeployEvent < Events::BaseEvent
    ENVIRONMENTS = %w(uat staging production).freeze

    def app_name
      (details['app_name'] || details['app'])&.downcase
    end

    def server
      servers.first
    end

    def version
      details['version'] || details['head_long']
    end

    def deployed_by
      details['deployed_by'] || details['user']
    end

    def environment
      details.fetch('environment', heroku_environment).try(:downcase)
    end

    def locale
      details.fetch('locale', heroku_locale).try(:downcase) || default_locale
    end

    private

    def heroku_environment
      app_name_extension if ENVIRONMENTS.include?(app_name_extension)
    end

    def heroku_locale
      app_name_prefix if Rails.configuration.deploy_regions.include?(app_name_prefix)
    end

    def default_locale
      if deployed_to_heroku?
        ShipmentTracker::DEFAULT_HEROKU_DEPLOY_LOCALE
      else
        ShipmentTracker::DEFAULT_DEPLOY_LOCALE
      end
    end

    def deployed_to_heroku?
      details.fetch('url', '').split('.')[-2] == 'herokuapp'
    end

    def app_name_extension
      return nil unless app_name
      app_name.split('-').last.downcase
    end

    def app_name_prefix
      return nil unless app_name
      app_name.split('-').first.downcase
    end

    def servers
      details.fetch('servers', servers_fallback)
    end

    def servers_fallback
      [details['server'] || details['url']].compact
    end
  end
end
