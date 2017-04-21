# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Repositories::ReleaseExceptionRepository do
  subject(:repository) { Repositories::ReleaseExceptionRepository.new }

  let(:repo_owner) { FactoryGirl.create(:repo_owner, email: 'test@example.com') }

  before do
    FactoryGirl.create(:git_repository_location, name: 'app1', uri: 'http://example.com/app1.git')
    FactoryGirl.create(:git_repository_location, name: 'app2', uri: 'http://example.com/app2.git')

    allow_any_instance_of(Repositories::RepoOwnershipRepository)
      .to receive(:owners_of).and_return([repo_owner])
    allow(CommitStatusUpdateJob).to receive(:perform_later)
  end

  describe '#release_exception_for_application' do
    it 'returns all release exceptions for a given app' do
      events = [
        create_exception_event(apps: [%w(app1 3)]),
        create_exception_event(apps: [%w(app2 2)]),
        create_exception_event(apps: [%w(app1 1)]),
      ]

      events.each { |event| repository.apply(event) }

      result = repository.release_exception_for_application(app_name: 'app1')

      expect(result.count).to eq(2)
    end

    context 'with specified time period' do
      it 'returns all release exceptions made within the given time period' do
        events = [
          create_exception_event(apps: [%w(app1 3)], created_at: Date.parse('01-05-2017')),
          create_exception_event(apps: [%w(app1 1)], created_at: Date.parse('01-03-2017')),
          create_exception_event(apps: [%w(app2 2)]),
        ]

        events.each { |event| repository.apply(event) }
        result = repository.release_exception_for_application(
          app_name: 'app1',
          from_date: Date.parse('01-02-2017'),
          to_date: Date.parse('01-04-2017'),
        )
        expect(result.count).to eq(1)
        expect(result.first).to have_attributes(
          submitted_at: Date.parse('01-03-2017'),
          versions: %w(1),
        )
      end
    end
  end

  describe '#apply' do
    context 'event is made by a repo owner' do
      let(:event) {
        build(
          :release_exception_event,
          apps: [%w(app1 1), %w(app2 2)],
          email: 'test@example.com',
          comment: 'Good to go',
          approved: false,
          created_at: Time.now,
        )
      }

      it 'creates an exception' do
        expect { repository.apply event }.to change { Snapshots::ReleaseException.count }.by(1)
      end

      it 'updates the commit status' do
        expect(CommitStatusUpdateJob).to receive(:perform_later)
          .with(full_repo_name: 'app1', sha: '1')

        expect(CommitStatusUpdateJob).to receive(:perform_later)
          .with(full_repo_name: 'app2', sha: '2')

        repository.apply event
      end
    end

    context 'event is made by someone that is not a repo owner' do
      let(:event) {
        build(
          :release_exception_event,
          apps: [%w(app1 1), %w(app2 2)],
          email: 'test2@example.com',
          comment: 'Good to go',
          approved: false,
          created_at: Time.now,
        )
      }

      it 'create an exception' do
        expect { repository.apply event }.to change { Snapshots::ReleaseException.count }.by(1)
      end
    end
  end

  describe '#table_name' do
    let(:active_record_class) { class_double(Snapshots::ReleaseException, table_name: 'the_table_name') }

    subject(:repository) { Repositories::ManualTestRepository.new(active_record_class) }

    it 'delegates to the active record class backing the repository' do
      expect(repository.table_name).to eq('the_table_name')
    end
  end

  def create_exception_event(options = {})
    default = {
      apps: [%w(app1 1), %w(app2 2)],
      email: 'test@example.com',
      comment: 'Good to go',
      approved: false,
      created_at: Time.now,
    }

    build(:release_exception_event, default.merge(options))
  end

  describe '#release_exception_for' do
    it 'returns the last project owner exception for any of the app versions' do
      t = [4.hours.ago, 3.hours.ago, 2.hours.ago, 1.hour.ago].map { |time| time.change(usec: 0) }

      events = [
        create_exception_event(created_at: t[0]),
        create_exception_event(apps: [%w(app2 2)], created_at: t[1]),
        create_exception_event(apps: [%w(app1 1)], created_at: t[3]),
        create_exception_event(approved: true, created_at: t[2]),
      ]

      events.each do |event|
        repository.apply(event)
      end

      result = repository.release_exception_for(versions: %w(1 2))

      expect(result).to eq(
        ReleaseException.new(
          repo_owner_id: repo_owner.id,
          approved: true,
          comment: 'Good to go',
          submitted_at: t[2],
          path: '/feature_reviews?apps%5Bapp1%5D=1&apps%5Bapp2%5D=2',
          versions: %w(1 2),
        ),
      )
    end

    context 'with at specified' do
      it 'returns the state at that moment' do
        times = [3.hours.ago, 2.hours.ago, 1.hour.ago].map { |t| t.change(usec: 0) }

        events = [
          create_exception_event(approved: false, created_at: times[0]),
          create_exception_event(approved: true, created_at: times[1]),
          create_exception_event(approved: false, created_at: times[2]),
        ]

        events.each do |event|
          repository.apply(event)
        end

        result = repository.release_exception_for(versions: %w(1 2), at: 2.hours.ago)

        expect(result).to eq(
          ReleaseException.new(
            repo_owner_id: repo_owner.id,
            approved: true,
            comment: 'Good to go',
            submitted_at: times[1],
            path: '/feature_reviews?apps%5Bapp1%5D=1&apps%5Bapp2%5D=2',
            versions: %w(1 2),
          ),
        )
      end
    end
  end
end
