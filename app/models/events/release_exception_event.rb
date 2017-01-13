# frozen_string_literal: true
require 'events/base_event'

module Events
  class ReleaseExceptionEvent < Events::BaseEvent
    def apps
      details.fetch('apps', [])
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
