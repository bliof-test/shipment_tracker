# frozen_string_literal: true
class DeployedCommit
  include Virtus.model

  attribute :app_name, String
  attribute :sha, String
  attribute :merged_by, String
  attribute :merged_at, Time
  attribute :deploys, Array

  def github_repo_url
    @github_repo_url ||= GitRepositoryLocation.github_url_for_app(app_name)
  end
end
