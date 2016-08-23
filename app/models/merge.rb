# frozen_string_literal: true
class Merge
  include Virtus.model

  attribute :app_name, String
  attribute :sha, String
  attribute :merged_by, String
  attribute :merged_at, Time
  attribute :deploys, Array

  def github_repo_urls
    @github_repo_url ||= GitRepositoryLocation.github_urls_for_apps([app_name])
  end
end
