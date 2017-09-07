# frozen_string_literal: true
module Repositories
  class GitRepoLocationRepository < Base
    def initialize(store = Snapshots::GitRepositoryLocation)
      @store = store
    end

    # Events::GitRepositoryLocationEvent
    def apply(event)
      return unless event.is_a?(Events::GitRepositoryLocationEvent)

      repo = GitRepositoryLocation.find_by(name: event.app_name)
      repo.required_checks = event.required_checks
      repo.save!
    end
  end
end
