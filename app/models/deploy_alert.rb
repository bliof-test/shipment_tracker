require 'repositories/deploy_repository'
require 'git_repository_loader'
require 'git_repository_location'

class DeployAlert
  attr_reader :deploy_env

  def self.auditable?(new_deploy)
    new_deploy.environment == 'production' && GitRepositoryLocation.app_names.include?(new_deploy.app_name)
  end

  def self.audit_message(new_deploy, previous_deploy = nil)
    github_repo = GitRepositoryLoader.from_rails_config.load(new_deploy.app_name)

    deploy_auditor = DeployAuditor.new(github_repo, new_deploy, previous_deploy)

    return alert_not_on_master(new_deploy) if deploy_auditor.unknown_or_not_on_master?

    alert_not_authorised(new_deploy) unless deploy_auditor.all_releases_authorised?
  end

  def self.alert_not_authorised(deploy)
    time = deploy.event_created_at.strftime('%F %H:%M%:z')
    "#{deploy.region&.upcase} Deploy Alert for #{deploy.app_name} at #{time}.\n#{deploy.deployed_by} " \
    "deployed #{deploy.version || 'unknown'}, release not authorised."
  end

  def self.alert_not_on_master(deploy)
    time = deploy.event_created_at.strftime('%F %H:%M%:z')
    "#{deploy.region&.upcase} Deploy Alert for #{deploy.app_name} at #{time}.\n#{deploy.deployed_by} " \
    "deployed #{deploy.version || 'unknown'} not on master branch."
  end

  class DeployAuditor
    def initialize(github_repo, new_deploy, previous_deploy = nil)
      @github_repo = github_repo
      @new_deploy = new_deploy
      @previous_deploy = previous_deploy
    end

    def unknown_or_not_on_master?
      @new_deploy.version.nil? || !@github_repo.commit_on_master?(@new_deploy.version)
    end

    def all_releases_authorised?
      auditable_commits = auditable_commits_list

      return false unless auditable_commits
      release_query = release_query_for(
        auditable_commits,
        @new_deploy.region,
        @github_repo,
        @new_deploy.app_name,
      )

      auditable_releases = release_query.deployed_releases

      auditable_releases.all?(&:authorised?)
    end

    private

    def release_query_for(auditable_commits, region, github_repo, app_name)
      Queries::ReleasesQuery.new(
        per_page: auditable_commits.size,
        region: region,
        git_repo: github_repo,
        app_name: app_name,
        commits: auditable_commits,
      )
    end

    def auditable_commits_list
      return [@github_repo.commit_for_version(@new_deploy.version)] unless @previous_deploy

      @github_repo.commits_between(@previous_deploy.version, @new_deploy.version, true)
    end
  end
end
