require 'repositories/deploy_repository'
require 'git_repository_loader'
require 'git_repository_location'

class DeployAlert
  attr_reader :deploy_env

  def self.auditable?(new_deploy)
    new_deploy.environment == 'production' && GitRepositoryLocation.app_names.include?(new_deploy.app_name)
  end

  def self.audit(old_deploy, new_deploy)
    return unless auditable?(new_deploy)

    github_repo = GitRepositoryLoader.from_rails_config.load(new_deploy.app_name)

    alert_not_on_master(new_deploy) if new_deploy.version.nil? || !github_repo.commit_on_master?(new_deploy.version)

    repo_loader = GitRepositoryLoader.from_rails_config
    git_repo = repo_loader.load(new_deploy.app_name)
    auditable_commits = git_repo.recent_commits_between(old_deploy.version, new_deploy.version)

    projection = Queries::ReleasesQuery.new(
      per_page: auditable_commits.size,
      region: new_deploy.region,
      git_repo: git_repo,
      app_name: new_deploy.app_name,
      commits: auditable_commits,
    )

    auditable_releases = projection.deployed_releases

    alert_not_authorised(new_deploy) unless auditable_releases.all?(&:authorised?)
  end

  def self.alert_not_authorised(deploy)
    time = deploy.event_created_at.strftime('%F %H:%M%:z')
    "#{deploy.region&.upcase} Deploy Alert for #{deploy.app_name} at #{time}. #{deploy.deployed_by} " \
    "deployed #{deploy.version || 'unknown'}, release not authorised."
  end

  def self.alert_not_on_master(deploy)
    time = deploy.event_created_at.strftime('%F %H:%M%:z')
    "#{deploy.region&.upcase} Deploy Alert for #{deploy.app_name} at #{time}. #{deploy.deployed_by} " \
    "deployed #{deploy.version || 'unknown'} not on master branch."
  end
end
