# frozen_string_literal: true
require 'rails_helper'
require 'repositories/updater'

RSpec.describe Repositories::Updater do
  describe '.from_rails_config' do
    it 'returns a configured updater' do
      expect(Repositories::Updater.from_rails_config.repositories).to eq(Rails.configuration.repositories)
    end
  end

  def repository_stub(repository)
    allow(repository).to receive(:apply)

    repository
  end

  let(:repository_1) { repository_stub(Repositories::BuildRepository.new(Snapshots::Build)) }
  let(:repository_2) { repository_stub(Repositories::DeployRepository.new(Snapshots::Deploy)) }
  let(:repositories) { [repository_1, repository_2] }

  subject(:updater) { Repositories::Updater.new(repositories) }

  describe '#run' do
    it 'feeds the events in ordered manner to each of the repositories' do
      events = create_list :jira_event, 2

      expect(repository_1).to receive(:apply).with(events[0]).ordered
      expect(repository_2).to receive(:apply).with(events[0]).ordered

      expect(repository_1).to receive(:apply).with(events[1]).ordered
      expect(repository_2).to receive(:apply).with(events[1]).ordered

      updater.run

      expect(repository_1.last_applied_event_id).to eq(events.last.id)
      expect(repository_2.last_applied_event_id).to eq(events.last.id)
    end

    context 'when given a hash with snapshot names and event ids' do
      it 'only snapshots up to the given event id for each repository' do
        allow(repository_1).to receive(:apply)
        allow(repository_2).to receive(:apply)

        events = create_list :jira_event, 3

        updater.run(upto_event: events.second.id)

        expect(repository_1.last_applied_event_id).to eq(events.second.id)
        expect(repository_2.last_applied_event_id).to eq(events.second.id)
      end
    end

    context 'when there are no new events' do
      it 'does not update the event count' do
        expect_any_instance_of(Snapshots::EventCount).to_not receive(:save)

        updater.run
      end
    end

    context 'with repositories that do not run in the background' do
      it 'will not apply any events' do
        create(:repo_ownership_event)

        repository = Repositories::RepoOwnershipRepository.new

        expect(repository).not_to receive(:apply)

        Repositories::Updater.new([repository]).run
      end

      it 'will apply events if the force option is set' do
        create(:repo_ownership_event)

        repository = Repositories::RepoOwnershipRepository.new

        expect(repository).to receive(:apply).and_return(true)

        Repositories::Updater.new([repository]).run(apply_to_all: true)
      end
    end
  end

  describe '#reset' do
    let(:store_1) { Snapshots::Build }
    let(:store_2) { Snapshots::Deploy }

    let(:repository_1) { Repositories::BuildRepository.new(store_1) }
    let(:repository_2) { Repositories::DeployRepository.new(store_2) }

    it 'wipes all repositories and what events they require' do
      events = [
        create(:circle_ci_event),
        create(:deploy_event),
      ]

      updater.run

      expect(store_1.count).to be > 0
      expect(store_2.count).to be > 0

      updater.reset

      expect(store_1.count).to eq(0)
      expect(store_2.count).to eq(0)

      expect(repository_1).to receive(:apply).with(events[0]).ordered
      expect(repository_2).to receive(:apply).with(events[0]).ordered
      expect(repository_1).to receive(:apply).with(events[1]).ordered
      expect(repository_2).to receive(:apply).with(events[1]).ordered

      updater.run
    end
  end

  describe '#recreate' do
    it 'resets and forces a run' do
      event = create(:repo_ownership_event)

      repository = Repositories::RepoOwnershipRepository.new
      allow(repository).to receive(:apply)

      Repositories::Updater.new([repository]).run(apply_to_all: true)

      last_updated_event = Snapshots::EventCount.last

      expect(repository).to receive(:apply).with(event)
      Repositories::Updater.new([repository]).recreate

      # Make sure that there was a reset
      expect(Snapshots::EventCount.find_by_id(last_updated_event.id)).to be_blank
    end
  end
end
