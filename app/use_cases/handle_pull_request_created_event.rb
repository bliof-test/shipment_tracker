# frozen_string_literal: true

require 'git_repository_location'

class HandlePullRequestCreatedEvent
  include SolidUseCase

  steps :validate, :post_not_found_status

  def validate(payload)
    return fail :base_not_master unless payload.base_branch_master?
    return fail :repo_not_under_audit unless GitRepositoryLocation.repo_tracked?(payload.full_repo_name)

    continue(payload)
  end

  def post_not_found_status(payload)
    CommitStatusNotFoundJob.perform_later(
      full_repo_name: payload.full_repo_name,
      sha: payload.head_sha,
    )

    continue(payload)
  end
end
