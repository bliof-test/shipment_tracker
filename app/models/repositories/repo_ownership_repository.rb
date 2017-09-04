# frozen_string_literal: true
module Repositories
  class RepoOwnershipRepository < Base
    def initialize(store = Snapshots::RepoOwnership)
      @store = store
    end

    # Events::RepoOwnershipEvent
    def apply(event)
      return unless event.is_a?(Events::RepoOwnershipEvent)

      repo_ownership = store.for(GitRepositoryLocation.new(name: event.app_name))
      repo_ownership.repo_owners = event.repo_owners
      repo_ownership.save!

      repo = GitRepositoryLocation.find_by(name: event.app_name)
      repo.required_checks = event.required_checks
      repo.save!

      repo_ownership.owner_emails.each do |email|
        owner = RepoOwner.find_or_initialize_by(email: email.address)
        owner.name = email.display_name if email.raw.include?('<')
        owner.save!
        owner
      end
    end

    def owners_of(repo)
      store.for(repo).owner_emails.addresses.map do |email|
        RepoOwner.find_by!(email: email.address)
      end
    end
  end
end
