# frozen_string_literal: true
class Deploy
  include Virtus.value_object

  values do
    attribute :app_name, String
    attribute :correct, Boolean
    attribute :deployed_by, String
    attribute :event_created_at, Time
    attribute :server, String
    attribute :region, String
    attribute :version, String
    attribute :environment, String
  end

  def deployed_at
    event_created_at
  end

  def commit
    git_repository_loader.commit_for_version(version)
  end

  private

  def git_repository_loader
    @git_repository_loader ||= GitRepositoryLoader.from_rails_config.load(app_name)
  end
end
