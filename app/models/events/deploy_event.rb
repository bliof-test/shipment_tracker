# frozen_string_literal: true

require 'events/base_event'
require 'git_repository_loader'

module Events
  class DeployEvent < Events::BaseEvent
    ENVIRONMENTS ||= %w[uat staging production].freeze

    def app_name
      details['app_name']&.downcase
    end

    def server
      servers.first
    end

    def version
      @version ||= full_sha(details['version'])
    end

    def deployed_by
      details['deployed_by']
    end

    def environment
      details['environment']&.downcase
    end

    def locale
      details.fetch('locale', ShipmentTracker::DEFAULT_DEPLOY_LOCALE)&.downcase
    end

    private

    def servers
      details.fetch('servers', [details['server']].compact)
    end

    def full_sha(sha)
      return if sha.nil? || sha.length > 40
      return sha if sha.length == 40

      git_repository_loader = GitRepositoryLoader.from_rails_config
      repo = git_repository_loader.load(app_name)
      repo.commit_for_version(sha).id
    end
  end
end
