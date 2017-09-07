# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Repositories::GitRepoLocationRepository do
  subject(:repository) { described_class.new }

  describe '#apply' do
    let!(:git_repo) { create(:git_repository_location, name: 'test', required_checks: %w(unit_tests)) }

    it 'will store a snapshot of the repo' do
      event = build(
        :git_repository_location_event,
        app_name: 'test',
        required_checks: %w(unit_tests integration_tests),
      )

      repository.apply(event)

      expect(Snapshots::GitRepositoryLocation.last).to have_attributes(
        name: 'test',
        required_checks: %w(unit_tests integration_tests),
      )
    end

    it 'will update already existing git repository location' do
      git_repo2 = create(:git_repository_location, name: 'test2', required_checks: %w(unit_tests integration_tests))

      event = build(
        :git_repository_location_event,
        app_name: 'test',
        required_checks: %w(integration_tests tickets_approval),
      )

      repository.apply(event)

      expect(GitRepositoryLocation.count).to eq(2)

      expect(git_repo.reload).to have_attributes(name: 'test', required_checks: %w(integration_tests tickets_approval))
      expect(git_repo2.reload).to have_attributes(name: 'test2', required_checks: %w(unit_tests integration_tests))
    end

    it 'will update the already existing snapshot' do
      event = build(
        :git_repository_location_event,
        app_name: 'test',
        required_checks: %w(tickets_approval),
      )

      event2 = build(
        :git_repository_location_event,
        app_name: 'test',
        required_checks: %w(unit_tests tickets_approval),
      )

      repository.apply(event)

      snapshot = Snapshots::GitRepositoryLocation.last

      expect { repository.apply(event2) }.to change { snapshot.reload.required_checks }
    end
  end
end
