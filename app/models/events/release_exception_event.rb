# frozen_string_literal: true
require 'events/base_event'

module Events
  class ReleaseExceptionEvent < Events::BaseEvent
    validate :validate_repo_admin_permissions

    def apps
      details.fetch('apps', [])
    end

    def path
      Factories::FeatureReviewFactory.new.create_from_apps(app_versions).path
    end

    def app_versions
      apps.each_with_object({}) do |app_info, memo|
        memo[app_info['name']] = app_info['version']
      end
    end

    def git_repos
      GitRepositoryLocation.where(name: app_names).to_a
    end

    def repo_owner
      RepoAdmin.find_or_initialize_by(email: email)
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

    private

    def app_names
      apps.map { |app| app['name'] }
    end

    def validate_repo_admin_permissions
      return if git_repos.any? { |repo| repo_owner.owner_of?(repo) }

      errors.add(:repo_owner, :not_allowed_to_add_release_exception)
      errors.add(:base, 'forbidden')
    end
  end
end
