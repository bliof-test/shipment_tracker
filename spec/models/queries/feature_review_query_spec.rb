# frozen_string_literal: true
require 'rails_helper'
require 'queries/feature_review_query'

RSpec.describe Queries::FeatureReviewQuery do
  let(:build_repository) { instance_double(Repositories::BuildRepository) }
  let(:manual_test_repository) { instance_double(Repositories::ManualTestRepository) }
  let(:ticket_repository) { instance_double(Repositories::TicketRepository) }
  let(:release_exception_repository) { instance_double(Repositories::ReleaseExceptionRepository) }

  let(:expected_builds) { double('expected builds') }
  let(:expected_qa_submissions) { double('expected qa submissions') }
  let(:expected_tickets) { double('expected tickets') }
  let(:expected_release_exception) { double('release_exception') }

  let(:expected_apps) { { 'app1' => '123' } }
  let(:versions) { {'app1' => ['123']} }

  let(:time) { Time.current }
  let(:feature_review) { new_feature_review(expected_apps) }
  let(:feature_review_with_statuses) { instance_double(FeatureReviewWithStatuses) }

  subject(:query) { Queries::FeatureReviewQuery.new(feature_review, at: time) }

  before do
    allow(Repositories::BuildRepository).to receive(:new).and_return(build_repository)
    allow(Repositories::ManualTestRepository).to receive(:new).and_return(manual_test_repository)
    allow(Repositories::TicketRepository).to receive(:new).and_return(ticket_repository)
    allow(Repositories::ReleaseExceptionRepository).to receive(:new).and_return(release_exception_repository)

    repository1 = instance_double(GitRepository, get_dependent_commits: [])
    allow_any_instance_of(GitRepositoryLoader).to receive(:load).with('app1').and_return(repository1)

    allow(build_repository).to receive(:builds_for)
      .with(apps: expected_apps, at: time)
      .and_return(expected_builds)
    allow(manual_test_repository).to receive(:qa_submissions_for)
      .with(versions: versions, at: time)
      .and_return(expected_qa_submissions)
    allow(release_exception_repository).to receive(:release_exception_for)
      .with(versions: expected_apps.values, at: time)
      .and_return(expected_release_exception)
    allow(ticket_repository).to receive(:tickets_for_path)
      .with(feature_review.path, at: time)
      .and_return(expected_tickets)
  end

  describe '#feature_review_with_statuses' do
    it 'returns a feature review with statuses' do
      expect(FeatureReviewWithStatuses).to receive(:new)
        .with(
          feature_review,
          builds: expected_builds,
          qa_submissions: expected_qa_submissions,
          tickets: expected_tickets,
          release_exception: expected_release_exception,
          at: time,
        )
        .and_return(feature_review_with_statuses)

      expect(query.feature_review_with_statuses).to eq(feature_review_with_statuses)
    end
  end
end
