# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Repositories::RepoOwnershipRepository do
  subject(:repository) { described_class.new }

  def apply_changes_to_repo_owners(*repo_owners_data)
    repo_owners_data.each do |repo_owners|
      repository.apply(build(:repo_ownership_event, repo_owners))
    end
  end

  describe '#apply' do
    it 'will store a snapshot of the repo owners for a repo' do
      event = build(
        :repo_ownership_event,
        app_name: 'test',
        repo_owners: 'Test <test@test.com>, test2@test.com',
      )

      repository.apply(event)

      expect(Snapshots::RepoOwnership.last)
        .to have_attributes(app_name: 'test', repo_owners: 'Test <test@test.com>, test2@test.com')
    end

    it 'will create a RepoAdmin record each of the owner without existing one' do
      event = build(
        :repo_ownership_event,
        app_name: 'test',
        repo_owners: 'Test <test@test.com>, test2@test.com',
      )

      repository.apply(event)

      repo_admins = RepoAdmin.all

      expect(repo_admins.size).to eq(2)
      expect(repo_admins.first).to have_attributes(name: 'Test', email: 'test@test.com')
      expect(repo_admins.second).to have_attributes(name: nil, email: 'test2@test.com')
    end

    it 'will update already existing repo owners' do
      repo_owner = create(:repo_admin, name: 'Test', email: 'test@test.com')
      repo_owner2 = create(:repo_admin, name: 'Test2', email: 'test2@test.com')

      event = build(
        :repo_ownership_event,
        app_name: 'test',
        repo_owners: 'Hello <test@test.com>, <test2@test.com>',
      )

      repository.apply(event)

      expect(RepoAdmin.count).to eq(2)

      expect(repo_owner.reload).to have_attributes(name: 'Hello', email: 'test@test.com')
      expect(repo_owner2.reload).to have_attributes(name: nil, email: 'test2@test.com')
    end

    it 'will update the already existing snapshot' do
      event = build(
        :repo_ownership_event,
        app_name: 'test',
        repo_owners: 'Test <test@test.com>, test2@test.com',
      )
      event2 = build(
        :repo_ownership_event,
        app_name: 'test',
        repo_owners: 'test2@test.com',
      )

      repository.apply(event)

      snapshot = Snapshots::RepoOwnership.last

      expect { repository.apply(event2) }.to change { snapshot.reload.repo_owners }
    end
  end

  describe '#owners_of' do
    it 'returns the repo owners of certain repository' do
      apply_changes_to_repo_owners(
        { app_name: 'test', repo_owners: 'John <test@example.com>, Ivan <test2@example.com>' },
        app_name: 'test2', repo_owners: 'John Snow <test@example.com>',
      )

      repo = create(:git_repository_location, name: 'test')

      owners = repository.owners_of(repo)

      expect(owners.size).to eq(2)
      expect(owners.map { |owner| [owner.name, owner.email] })
        .to match_array([['John Snow', 'test@example.com'], ['Ivan', 'test2@example.com']])
    end

    it 'is an empty array by default' do
      repo = build(:git_repository_location, name: 'test')

      expect(repository.owners_of(repo)).to eq([])
    end
  end
end
