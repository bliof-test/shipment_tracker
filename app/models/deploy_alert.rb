# frozen_string_literal: true
require 'repositories/deploy_repository'
require 'git_repository_loader'
require 'git_repository_location'

class DeployAlert
  attr_reader :deploy_env

  def self.auditable?(current_deploy)
    return false unless current_deploy.environment == 'production'
    GitRepositoryLocation.app_names.include?(current_deploy.app_name)
  end

  def self.audit_message(current_deploy, previous_deploy = nil)
    deploy_auditor = DeployAuditor.new(current_deploy, previous_deploy)

    if deploy_auditor.unknown_version?
      alert_unknown_version(current_deploy)
    elsif deploy_auditor.not_on_master?
      alert_not_on_master(current_deploy)
    elsif deploy_auditor.rollback?
      alert_rollback(current_deploy)
    elsif !deploy_auditor.recent_releases_authorised?
      alert_not_authorised(current_deploy, deploy_auditor)
    end
  end

  def self.alert_not_authorised(deploy, deploy_auditor)
    "#{alert_header(deploy)}Release not authorised; Feature Review not approved.\n" \
    "#{deploy_auditor.unauthorised_releases}"
  end

  def self.alert_not_on_master(deploy)
    "#{alert_header(deploy)}Version does not exist on GitHub master branch."
  end

  def self.alert_unknown_version(deploy)
    "#{alert_header(deploy)}Deploy event sent to Shipment Tracker contains an unknown software version."
  end

  def self.alert_rollback(deploy)
    "#{alert_header(deploy)}Old release deployed. Was the rollback intentional?"
  end

  def self.alert_header(deploy)
    time = deploy.deployed_at.strftime('%F %H:%M%:z')
    "#{deploy.region.upcase} Deploy Alert for #{deploy.app_name} at #{time}.\n" \
    "#{deploy.deployed_by} deployed #{deploy.version || 'unknown version'}.\n"
  end
  private_class_method :alert_header

  class DeployAuditor
    def initialize(current_deploy, previous_deploy = nil)
      @current_deploy = current_deploy
      @git_repo = GitRepositoryLoader.from_rails_config.load(current_deploy.app_name)
      @previous_deploy = previous_deploy if git_repo.exists?(previous_deploy&.version, allow_short_sha: true)
    end

    def not_on_master?
      !git_repo.commit_on_master?(current_deploy.version)
    end

    def unknown_version?
      !git_repo.exists?(current_deploy.version, allow_short_sha: true)
    end

    def rollback?
      return false unless previous_deploy
      git_repo.ancestor_of?(current_deploy.version, previous_deploy.version)
    end

    def recent_releases_authorised?
      recent_deployed_releases.all?(&:authorised?)
    end

    def recent_deployed_releases
      release_query_for(auditable_commits, current_deploy.region, current_deploy.app_name).deployed_releases
    end

    def unauthorised_releases
      recent_deployed_releases.map { |release|
        "* #{release.commit.author_name} #{release.commit.id} #{release.authorised? ? 'Approved' : 'Not Approved'}"
      }.join("\n")
    end

    private

    attr_reader :current_deploy, :previous_deploy, :git_repo

    def release_query_for(auditable_commits, region, app_name)
      Queries::ReleasesQuery.new(
        per_page: auditable_commits.size,
        region: region,
        git_repo: git_repo,
        app_name: app_name,
        commits: auditable_commits,
      )
    end

    def auditable_commits
      @commits ||= if previous_deploy
                     git_repo.commits_between(
                       previous_deploy.version,
                       current_deploy.version,
                       simplify: true,
                       newest_first: true,
                     )
                   else
                     [git_repo.commit_for_version(current_deploy.version)]
                   end
    end
  end
end
