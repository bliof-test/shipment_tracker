# frozen_string_literal: true

class HandlePullRequestCreatedEvent
  include SolidUseCase
  include PullRequestEventValidatable

  steps :validate, :post_not_found_status, :auto_link_ticket

  def post_not_found_status(payload)
    CommitStatusNotFoundJob.perform_later(
      full_repo_name: payload.full_repo_name,
      sha: payload.head_sha,
    )

    continue(payload)
  end

  def auto_link_ticket(payload)
    AutoLinkTicketJob.perform_later(
      repo_name: payload.repo_name,
      head_sha: payload.head_sha,
      branch_name: payload.branch_name,
      title: payload.title,
    )

    continue(payload)
  end
end
