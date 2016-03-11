require 'repositories/deploy_repository'
require 'git_repository_loader'
require 'git_repository_location'

class DeployAlert
  attr_reader :deploy_env

  def self.auditable?(new_deploy)
    new_deploy.environment == 'production' && GitRepositoryLocation.app_names.include?(new_deploy.app_name)
  end

  def self.audit_message(new_deploy, previous_deploy = nil)
    deploy_auditor = DeployAuditor.new(new_deploy, previous_deploy)

    if deploy_auditor.unknown_version?
      alert_unknown_version(new_deploy)
    elsif deploy_auditor.not_on_master?
      alert_not_on_master(new_deploy)
    elsif !deploy_auditor.recent_releases_authorised?
      alert_not_authorised(new_deploy)
    end
  end

  def self.alert_not_authorised(deploy)
    alert_header(deploy).concat(
      "#{deploy.deployed_by} deployed #{deploy.version}, release not authorised, Feature Review not approved."
    )
  end

  def self.alert_not_on_master(deploy)
    alert_header(deploy).concat(
      "#{deploy.deployed_by} deployed #{deploy.version} which is not on GitHub master branch."
    )
  end

  def self.alert_unknown_version(deploy)
    alert_header(deploy).concat(
      "#{deploy.deployed_by} deployed but deploy event did not contain a software version."
    )
  end

  def self.alert_header(deploy)
    time = deploy.event_created_at.strftime('%F %H:%M%:z')
    "#{deploy.region.upcase} Deploy Alert for #{deploy.app_name} at #{time}.\n"
  end
  private_class_method :alert_header

  class DeployAuditor
    def initialize(new_deploy, previous_deploy = nil)
      @new_deploy = new_deploy
      @previous_deploy = previous_deploy
      @git_repo = GitRepositoryLoader.from_rails_config.load(new_deploy.app_name)
    end

    def not_on_master?
      !git_repo.commit_on_master?(new_deploy.version)
    end

    def unknown_version?
      new_deploy.version.nil?
    end

<<<<<<< 279c3f6e8d745d675a9791266308179fee4bd4d5
    def recent_releases_authorised?
      release_query = release_query_for(
        auditable_commits,
        @new_deploy.region,
        @git_repo,
        @new_deploy.app_name,
      )

=======


    def recent_releases_authorised?
      return false unless auditable_commits
      release_query = release_query_for(auditable_commits, new_deploy.region, git_repo, new_deploy.app_name)
>>>>>>> :art: Minor refactor
      release_query.deployed_releases.all?(&:authorised?)
    end

    private

    attr_reader :new_deploy, :previous_deploy, :git_repo

    def release_query_for(auditable_commits, region, git_repo, app_name)
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
                     git_repo.commits_between(previous_deploy.version, new_deploy.version, simplify: true)
                   else
                     [git_repo.commit_for_version(new_deploy.version)]
                   end
    end
  end
end
