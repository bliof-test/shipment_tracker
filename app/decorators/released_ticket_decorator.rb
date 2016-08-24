# frozen_string_literal: true
class ReleasedTicketDecorator < SimpleDelegator
  def initialize(released_ticket)
    super(released_ticket)
  end

  def deployed_commits
    uniq_deploys = deploys.uniq { |deploy| [deploy['app'], deploy['version']] }
    uniq_deploys.map do |deploy|
      commit = commit_for_app_and_version(deploy['app'], deploy['version'])
      associate_deploys_to_app_commit(deploy['app'], commit)
    end
  end

  private

  def commit_for_app_and_version(app_name, version)
    git_repository_loader_for(app_name).commit_for_version(version)
  end

  def deploys_for_app_and_version(app_name, version)
    deploys_for_app_and_version = deploys.select { |deploy|
      deploy['app'] == app_name && deploy['version'] == version
    }
    deploys_for_app_and_version.map do |deploy|
      Deploy.new({
        app_name: deploy['app'],
        deployed_by: deploy['deployed_by'],
        event_created_at: deploy['deployed_at'],
      }.merge(deploy))
    end
  end

  def associate_deploys_to_app_commit(app_name, commit)
    GitCommitWithDeploys.new(
      commit,
      deploys: deploys_for_app_and_version(app_name, commit.id),
    )
  end

  def git_repository_loader_for(app_name)
    @git_repository_loader ||= GitRepositoryLoader.from_rails_config.load(app_name)
  end
end
