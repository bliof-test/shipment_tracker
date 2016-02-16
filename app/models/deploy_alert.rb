require 'repositories/deploy_repository'
require 'git_repository_loader'
require 'git_repository_location'

class DeployAlert
  attr_reader :deploy_env

  def self.auditable?(deploy)
    deploy.environment == 'production' && GitRepositoryLocation.app_names.include?(deploy.app_name)
  end

  def self.audit(deploy)
    return unless auditable?(deploy)

    github_repo = GitRepositoryLoader.from_rails_config.load(deploy.app_name)

    alert_not_on_master(deploy) unless github_repo.commit_on_master?(deploy.version)

    # @deploy_repo = Repositories::DeployRepository.new
    # deploy_region = deploy_vo.region
    # deploys = @deploy_repo.deploys_ordered_by_id('desc', environment: deploy_env, region: deploy_region)
    # last_deploy, before_last_deploy = deploys[0..1]
  end

  def self.alert_not_on_master(deploy)
    time = deploy.event_created_at.strftime('%F %H:%M%:z')
    "Deploy Alert for #{deploy.app_name} at #{time}. #{deploy.deployed_by} " \
    "deployed version #{deploy.version} not on master branch."
  end
end
