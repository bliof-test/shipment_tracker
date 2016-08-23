# frozen_string_literal: true
class ReleasedTicketDecorator < SimpleDelegator

  def initialize(released_ticket)
    super(released_ticket)
  end

  def deployed_commits
    uniq_deploys = deploys.uniq { |deploy| [deploy['app'], deploy['version']] }
    uniq_deploys.map { |deploy| DeployedCommit.new(build_hash(deploy)) }
  end

  private

  def build_hash(deploy)
    { app_name: deploy['app'],
      deploys: related_deploys(deploy) }
      .merge(commit_info(deploy))
  end

  def commit_info(deploy)
    deployed_commit = git_repository_loader_for(deploy['app']).commit_for_version(deploy['version'])
    { sha: deployed_commit.id, merged_by: deployed_commit.author_name, merged_at: deployed_commit.time }
  end

  def related_deploys(base_deploy)
    deploys.select { |deploy|
      base_deploy['app'] == deploy['app'] && base_deploy['version'] == deploy['version']
    }.map { |deploy| Deploy.new({ app_name: deploy['app'], deployed_by: deploy['deployed_by'], event_created_at: deploy['deployed_at'] }.merge(deploy)) }
  end

  def git_repository_loader_for(app_name)
    @git_repository_loader ||= GitRepositoryLoader.from_rails_config.load(app_name)
  end
end