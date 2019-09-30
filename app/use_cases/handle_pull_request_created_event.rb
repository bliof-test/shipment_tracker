# frozen_string_literal: true

class HandlePullRequestCreatedEvent
  include SolidUseCase
  include PullRequestEventValidatable

  steps :validate, :post_not_found_status

  def post_not_found_status(payload)
    CommitStatusNotFoundJob.perform_later(
      full_repo_name: payload.full_repo_name,
      sha: payload.head_sha,
    )

    continue(payload)
  end
end
