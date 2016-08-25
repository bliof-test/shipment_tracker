# frozen_string_literal: true
class ReleasedTicketDecorator < SimpleDelegator
  def initialize(released_ticket)
    super(released_ticket)
  end

  def deployed_commits
    grouped_deploys = deploy_objects.group_by { |deploy| [deploy.app_name, deploy.version] }
    grouped_deploys.values.map { |deploys| git_commit_with_deploys(deploys) }
  end

  private

  def deploy_objects
    @deploy_objects ||= deploys.map { |deploy|
      Deploy.new({
        app_name: deploy['app'],
        deployed_by: deploy['deployed_by'],
        deployed_at: deploy['deployed_at'],
      }.merge(deploy))
    }
  end

  def git_commit_with_deploys(deploys)
    GitCommitWithDeploys.new(
      deploys.first.commit,
      deploys: deploys,
    )
  end
end
