# frozen_string_literal: true

require 'git_commit'

class GitCommitWithDeploys < SimpleDelegator
  attr_reader :deploys, :app_name

  def initialize(git_commit, deploys: [])
    super(git_commit)
    @deploys = deploys
    @app_name = deploys&.first&.app_name
  end

  def merged_by
    author_name
  end

  def merged_at
    time
  end

  def github_repo_url
    @github_repo_url ||= GitRepositoryLocation.github_url_for_app(app_name)
  end
end
