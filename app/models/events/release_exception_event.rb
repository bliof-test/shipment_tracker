# frozen_string_literal: true
require 'events/base_event'

module Events
  class ReleaseExceptionEvent < Events::BaseEvent
    def apps
      details.fetch('apps', [])
    end

    def path
      app_versions = apps.each_with_object({}) do |app_info, memo|
        memo[app_info['name']] = app_info['version']
      end

      Factories::FeatureReviewFactory.new.create_from_apps(app_versions).path
    end

    def git_repos
      GitRepositoryLocation.where(name: apps.map { |app| app['name'] }).to_a
    end

    def repo_owner
      RepoOwner.find_or_initialize_by(email: email)
    end

    def versions
      apps.map { |app| app.fetch('version') }
    end

    def email
      details.fetch('email', nil)
    end

    def comment
      details.fetch('comment', '')
    end

    def approved?
      details.fetch('status', nil) == 'approved'
    end
  end
end
