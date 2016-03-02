require 'git_repository_location'
require 'pull_request_status'

class HandlePullRequestEvent
  include SolidUseCase

  steps :validate, :reset_pr_status

  def validate(payload)
    return fail :not_auditable unless relevant_pr?(payload.action) && audited_repo?(payload.full_repo_name)

    continue(payload)
  end

  def reset_pr_status(payload)
    status_options = { full_repo_name: payload.full_repo_name, sha: payload.head_sha }

    PullRequestStatus.new.reset(status_options)
    PullRequestUpdateJob.perform_later(status_options)

    continue(payload)
  end

  private

  def relevant_pr?(action)
    action == 'opened' || action == 'synchronize'
  end

  def audited_repo?(full_repo_name)
    GitRepositoryLocation.repo_exists?(full_repo_name)
  end
end
