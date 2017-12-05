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
      repo_ownership.repo_approvers = event.repo_approvers
      repo_ownership.save!

      save_emails(repo_ownership.owner_emails)
      save_emails(repo_ownership.approver_emails)
    end

    def owners_of(repo)
      store.for(repo).owner_emails.addresses.map do |email|
        RepoOwner.find_by!(email: email.address)
      end
    end

    def approvers_of(repo)
      store.for(repo).approver_emails.addresses.map do |email|
        RepoOwner.find_by!(email: email.address)
      end
    end

    private

    def save_emails(emails)
      emails.each do |email|
        owner = RepoOwner.find_or_initialize_by(email: email.address)
        owner.name = email.display_name if email.raw.include?('<')
        owner.save!
        owner
      end
    end
  end
end
