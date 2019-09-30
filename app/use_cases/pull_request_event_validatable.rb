# frozen_string_literal: true

require 'git_repository_location'

module PullRequestEventValidatable
  include SolidUseCase

  def validate(payload)
    return fail :base_not_master unless payload.base_branch_master?
    return fail :repo_not_under_audit unless GitRepositoryLocation.repo_tracked?(payload.full_repo_name)

    continue(payload)
  end
end
