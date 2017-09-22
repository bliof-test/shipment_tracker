# frozen_string_literal: true
require 'rails_helper'
require 'feature_review_with_statuses'

RSpec.describe FeatureReviewWithStatuses do
  let(:tickets) { double(:tickets) }
  let(:qa_submissions) { [] }
  let(:unit_test_results) { double(:unit_test_results, values: []) }
  let(:integration_test_results) { double(:integration_test_results, values: []) }
  let(:release_exception) { double(:release_exception) }
  let(:apps) { { 'app1' => 'xxx', 'app2' => 'yyy' } }
  let(:app_names) { apps.keys }
  let(:versions) { apps.values }

  let(:feature_review) { instance_double(FeatureReview, app_versions: apps, versions: versions, app_names: app_names) }
  let(:query_time) { Time.parse('2014-08-10 14:40:48 UTC') }

  subject(:decorator) {
    FeatureReviewWithStatuses.new(
      feature_review,
      unit_test_results: unit_test_results,
      integration_test_results: integration_test_results,
      release_exception: release_exception,
      qa_submissions: qa_submissions,
      tickets: tickets,
      at: query_time,
    )
  }

  it 'returns all necessary fields as initialized' do
    expect(decorator.unit_test_results).to eq(unit_test_results)
    expect(decorator.release_exception).to eq(release_exception)
    expect(decorator.qa_submissions).to eq(qa_submissions)
    expect(decorator.integration_test_results).to eq(integration_test_results)
    expect(decorator.tickets).to eq(tickets)
    expect(decorator.time).to eq(query_time)
  end

  context 'when initialized without parameters' do
    let(:decorator) { described_class.new(feature_review) }

    it 'returns the expected default values' do
      expect(decorator.release_exception).to eq(nil)
      expect(decorator.qa_submissions).to eq(nil)
      expect(decorator.unit_test_results).to eq({})
      expect(decorator.integration_test_results).to eq({})
      expect(decorator.release_exception).to eq(nil)
      expect(decorator.tickets).to eq([])
      expect(decorator.time).to eq(nil)
    end
  end

  describe '#apps_with_latest_commit' do
    let(:repository_loader) { instance_double(GitRepositoryLoader) }
    let(:repository) { instance_double(GitRepository) }

    let(:commit_1) { instance_double(GitCommit, id: versions.first, associated_ids: nil) }
    let(:commit_2) { instance_double(GitCommit, id: versions.second, associated_ids: nil) }

    before do
      allow(GitRepositoryLoader).to receive(:from_rails_config).and_return(repository_loader)
      allow(repository_loader).to receive(:load).and_return(repository)

      allow(repository).to receive(:get_descendant_commits_of_branch).with(versions.first)
        .and_return(dependent_commits_1)
      allow(repository).to receive(:get_descendant_commits_of_branch).with(versions.second)
        .and_return(dependent_commits_2)
    end

    context 'when the latest commit is not a merge commit' do
      let(:dependent_commits_1) { [] }
      let(:dependent_commits_2) { [] }
      let(:expected_results) do
        [
          [app_names.first, commit_1],
          [app_names.second, commit_2],
        ]
      end

      before do
        allow(repository).to receive(:commit_for_version).with(versions.first)
          .and_return(commit_1)
        allow(repository).to receive(:commit_for_version).with(versions.second)
          .and_return(commit_2)
      end

      it 'returns the app_name and the very same commit' do
        expect(decorator.apps_with_latest_commit).to eq(expected_results)
      end
    end

    context 'when the latest commit is a merge commit' do
      let(:dependent_commits_1) { [instance_double(GitCommit, id: versions.first, associated_ids: nil)] }
      let(:dependent_commits_2) { [instance_double(GitCommit, id: versions.second, associated_ids: nil)] }
      let(:expected_results) do
        [
          [app_names.first, dependent_commits_1.first],
          [app_names.second, dependent_commits_2.first],
        ]
      end

      it 'does not receive commit_for_version' do
        expect(repository).not_to receive(:commit_for_version)
      end

      it 'returns the app_name and the most recent dependent commit' do
        expect(decorator.apps_with_latest_commit).to eq(expected_results)
      end
    end
  end

  describe '#github_repo_urls' do
    let(:app_names) { %w(app1 app2) }
    let(:feature_review) { instance_double(FeatureReview, app_names: app_names) }
    let(:github_urls) { { 'app1' => 'url1', 'app2' => 'url2' } }

    before do
      allow(GitRepositoryLocation).to receive(:github_urls_for_apps).with(app_names).and_return(github_urls)
    end

    it 'returns the repo URLs for the apps under review' do
      expect(decorator.github_repo_urls).to eq(github_urls)
    end
  end

  describe '#unit_test_result_status' do
    context 'when all unit test results pass' do
      let(:unit_test_results) do
        {
          'frontend' => FactoryGirl.build(:unit_test_build, success: true),
          'backend'  => FactoryGirl.build(:unit_test_build, success: true),
        }
      end

      it 'returns :success' do
        expect(decorator.unit_test_result_status).to eq(:success)
      end

      context 'but some unit test results are missing' do
        let(:unit_test_results) do
          {
            'frontend' => FactoryGirl.build(:unit_test_build, success: true),
            'backend'  => FactoryGirl.build(:unit_test_build),
          }
        end

        it 'returns nil' do
          expect(decorator.unit_test_result_status).to eq(nil)
        end
      end
    end

    context 'when any of the unit test results fails' do
      let(:unit_test_results) do
        {
          'frontend' => FactoryGirl.build(:unit_test_build, success: false),
          'backend'  => FactoryGirl.build(:unit_test_build, success: true),
        }
      end

      it 'returns :failure' do
        expect(decorator.unit_test_result_status).to eq(:failure)
      end
    end
  end

  describe '#integration_test_result_status' do
    context 'when all integration test results pass' do
      let(:integration_test_results) do
        {
          'frontend' => FactoryGirl.build(:integration_test_build, success: true),
          'backend'  => FactoryGirl.build(:integration_test_build, success: true),
        }
      end

      it 'returns :success' do
        expect(decorator.integration_test_result_status).to eq(:success)
      end

      context 'but some unit test results are missing' do
        let(:integration_test_results) do
          {
            'frontend' => FactoryGirl.build(:integration_test_build, success: true),
            'backend'  => FactoryGirl.build(:integration_test_build),
          }
        end

        it 'returns nil' do
          expect(decorator.integration_test_result_status).to eq(nil)
        end
      end
    end

    context 'when any of the unit test results is failure' do
      let(:integration_test_results) do
        {
          'frontend' => FactoryGirl.build(:integration_test_build, success: false),
          'backend'  => FactoryGirl.build(:integration_test_build, success: true),
        }
      end

      it 'returns :failure' do
        expect(decorator.integration_test_result_status).to eq(:failure)
      end
    end
  end

  describe '#release_exception_status' do
    context 'when the repo owner has approved the feature_review' do
      let(:release_exception) { ReleaseException.new(approved: true) }

      it 'returns :success' do
        expect(decorator.release_exception_status).to eq(:success)
      end
    end

    context 'when the repo owner has rejected the feature_review' do
      let(:release_exception) { ReleaseException.new(approved: false) }

      it 'returns :failure' do
        expect(decorator.release_exception_status).to eq(:failure)
      end
    end

    context 'when the release_exception is missing' do
      let(:release_exception) { nil }

      it 'returns nil' do
        expect(decorator.release_exception_status).to be nil
      end
    end
  end

  describe '#unit_test_result_status' do
    context 'when all unit test results pass' do
      let(:unit_test_results) do
        {
          'frontend' => FactoryGirl.build(:unit_test_build, success: true),
          'backend'  => FactoryGirl.build(:unit_test_build, success: true),
        }
      end

      it 'returns :success' do
        expect(decorator.unit_test_result_status).to eq(:success)
      end

      context 'but some unit test results are missing' do
        let(:unit_test_results) do
          {
            'frontend' => FactoryGirl.build(:unit_test_build, success: true),
            'backend'  => FactoryGirl.build(:unit_test_build),
          }
        end

        it 'returns nil' do
          expect(decorator.unit_test_result_status).to eq(nil)
        end
      end
    end

    context 'when any of the unit test results fails' do
      let(:unit_test_results) do
        {
          'frontend' => FactoryGirl.build(:unit_test_build, success: false),
          'backend'  => FactoryGirl.build(:unit_test_build, success: true),
        }
      end

      it 'returns :failure' do
        expect(decorator.unit_test_result_status).to eq(:failure)
      end
    end
  end

  describe '#qa_status' do
    context 'when QA submission is accepted' do
      let(:qa_submissions) { [QaSubmission.new(accepted: true)] }

      it 'returns :success' do
        expect(decorator.qa_status).to eq(:success)
      end
    end

    context 'when QA submission is rejected' do
      let(:qa_submissions) { [QaSubmission.new(accepted: false)] }

      it 'returns :failure' do
        expect(decorator.qa_status).to eq(:failure)
      end
    end

    context 'when QA submission is missing' do
      let(:qa_submissions) { nil }

      it 'returns nil' do
        expect(decorator.qa_status).to be nil
      end
    end
  end

  describe '#summary_status' do
    context 'when status of builds, and QA submission are success' do
      let(:integration_test_build) { { 'frontend' => FactoryGirl.build(:integration_test_build, success: true) } }
      let(:unit_test_build) { { 'frontend' => FactoryGirl.build(:unit_test_build, success: true) } }
      let(:qa_submissions) { [QaSubmission.new(accepted: true)] }

      it 'returns :success' do
        expect(decorator.summary_status).to eq(:success)
      end
    end

    context 'when any status of builds, or QA submission is failed' do
      let(:integration_test_build) { { 'frontend' => FactoryGirl.build(:integration_test_build, success: true) } }
      let(:unit_test_build) { { 'frontend' => FactoryGirl.build(:unit_test_build, success: true) } }
      let(:qa_submissions) { [QaSubmission.new(accepted: false)] }

      it 'returns :failure' do
        expect(decorator.summary_status).to eq(:failure)
      end
    end

    context 'when no status is a failure but at least one is a warning' do
      let(:qa_submissions) { [QaSubmission.new(accepted: true)] }
      let(:unit_test_results) { { 'frontend' => FactoryGirl.build(:unit_test_build) } }
      let(:integration_test_results) { { 'frontend' => FactoryGirl.build(:integration_test_build) } }

      it 'returns nil' do
        expect(decorator.summary_status).to be(nil)
      end
    end
  end

  describe '#authorised?' do
    let(:feature_review_with_statuses) {
      FeatureReviewWithStatuses.new(feature_review, tickets: tickets)
    }

    subject { feature_review_with_statuses.authorised? }

    context 'when there are no tickets' do
      let(:tickets) { [] }
      it { is_expected.to be false }
    end

    context 'when all tickets are authorised' do
      let(:tickets) {
        [
          instance_double(Ticket, authorised?: true),
          instance_double(Ticket, authorised?: true),
        ]
      }
      it { is_expected.to be true }
    end

    context 'when at least one ticket is unauthorised' do
      let(:tickets) {
        [
          instance_double(Ticket, authorised?: false),
          instance_double(Ticket, authorised?: true),
        ]
      }

      it { is_expected.to be false }

      context 'but it is approved by the repo owner' do
        let(:release_exception) { instance_double(ReleaseException, approved?: true) }
        let(:feature_review_with_statuses) {
          FeatureReviewWithStatuses.new(
            feature_review,
            tickets: tickets,
            release_exception: release_exception)
        }

        subject { feature_review_with_statuses.authorised? }

        it { is_expected.to be true }
      end
    end
  end

  describe '#tickets_approval_status' do
    subject { FeatureReviewWithStatuses.new(feature_review, tickets: tickets).tickets_approval_status }

    context 'when there are no tickets' do
      let(:tickets) { [] }
      it { is_expected.to be nil }
    end

    context 'when all associated tickets are approved' do
      let(:tickets) {
        [
          instance_double(Ticket, approved?: true),
          instance_double(Ticket, approved?: true),
        ]
      }
      it { is_expected.to be :success }
    end

    context 'when some associated tickets are not approved' do
      let(:tickets) {
        [
          instance_double(Ticket, approved?: false),
          instance_double(Ticket, approved?: true),
        ]
      }
      it { is_expected.to be :failure }
    end
  end

  describe '#authorisation_status' do
    subject { FeatureReviewWithStatuses.new(feature_review, tickets: tickets).authorisation_status }

    context 'when there are no associated tickets' do
      let(:tickets) { [] }
      it { is_expected.to be :not_approved }
    end

    context 'when any associated tickets are not approved' do
      let(:tickets) {
        [
          instance_double(Ticket, approved?: false, authorised?: false),
          instance_double(Ticket, approved?: true, authorised?: true),
        ]
      }
      it { is_expected.to be :not_approved }
    end

    context 'when all associated tickets are approved after Feature Review offered' do
      let(:tickets) {
        [
          instance_double(Ticket, approved?: true, authorised?: true),
          instance_double(Ticket, approved?: true, authorised?: true),
        ]
      }
      it { is_expected.to be :approved }
    end

    context 'when any associated tickets are approved before Feature Review offered' do
      let(:tickets) {
        [
          instance_double(Ticket, approved?: true, authorised?: true),
          instance_double(Ticket, approved?: true, authorised?: false),
        ]
      }
      it { is_expected.to be :requires_reapproval }
    end

    context 'when it is approved by a repo owner' do
      let(:release_exception) { ReleaseException.new(approved: true) }
      let(:feature_review_with_statuses) {
        FeatureReviewWithStatuses.new(
          feature_review,
          tickets: tickets,
          release_exception: release_exception,
        )
      }

      subject { feature_review_with_statuses.authorisation_status }

      it { is_expected.to be :approved }
    end
  end

  describe '#approved_at' do
    subject { FeatureReviewWithStatuses.new(feature_review, tickets: tickets).approved_at }

    let(:approval_time) { Time.current }

    context 'when all associated tickets are approved' do
      let(:tickets) {
        [
          instance_double(Ticket, approved?: true, approved_at: approval_time, authorised?: true),
          instance_double(Ticket, approved?: true, approved_at: approval_time - 1.hour, authorised?: true),
        ]
      }

      it 'returns the approval time of the ticket that was approved last' do
        expect(subject).to eq(approval_time)
      end
    end

    context 'when any associated tickets are not approved' do
      let(:tickets) {
        [
          instance_double(Ticket, approved?: false, approved_at: nil, authorised?: false),
          instance_double(Ticket, approved?: true, approved_at: approval_time, authorised?: false),
        ]
      }

      it { is_expected.to be_nil }

      context 'when there is a release_exception_status' do
        let(:release_exception) { ReleaseException.new(approved: true, submitted_at: approval_time) }

        subject {
          FeatureReviewWithStatuses.new(
            feature_review,
            tickets: tickets,
            release_exception: release_exception,
          ).approved_at
        }

        it 'returns the approval time of the ticket that was approved last' do
          expect(subject).to eq(approval_time)
        end
      end
    end
  end

  describe '#tickets_approved?' do
    subject { FeatureReviewWithStatuses.new(feature_review, tickets: tickets).tickets_approved? }

    context 'when all tickets are approved' do
      let(:tickets) {
        [
          instance_double(Ticket, approved?: true),
          instance_double(Ticket, approved?: true),
        ]
      }
      it { is_expected.to be true }
    end

    context 'when some tickets are not approved' do
      let(:tickets) {
        [
          instance_double(Ticket, approved?: true),
          instance_double(Ticket, approved?: false),
        ]
      }
      it { is_expected.to be false }
    end

    context 'when there are no tickets' do
      let(:tickets) { [] }
      it { is_expected.to be false }
    end
  end

  describe '#tickets_authorised?' do
    subject { FeatureReviewWithStatuses.new(feature_review, tickets: tickets).send(:tickets_authorised?) }

    context 'when all tickets are authorised' do
      let(:tickets) {
        [
          instance_double(Ticket, authorised?: true),
          instance_double(Ticket, authorised?: true),
        ]
      }
      it { is_expected.to be true }
    end

    context 'when some tickets are not authorised' do
      let(:tickets){
        [
          instance_double(Ticket, authorised?: true),
          instance_double(Ticket, authorised?: false),
        ]
      }
      it { is_expected.to be false }
    end

    context 'when there are no tickets' do
      let(:tickets) { [] }
      it { is_expected.to be false }
    end
  end

  describe '#required_checks_passed?' do
    subject {
      FeatureReviewWithStatuses.new(
        feature_review,
        tickets: tickets,
        integration_test_results: integration_test_results,
        unit_test_results: unit_test_results,
        qa_submissions: qa_submissions,
        release_exception: release_exception,
      ).send(:required_checks_passed?)
    }

    let!(:repository) { GitRepositoryLocation.create(name: 'app1', uri: '/app1', required_checks: required_checks) }

    context 'when no checks are set' do
      let(:required_checks) { [] }

      it { is_expected.to be true }
    end

    context 'when integration_tests is selected' do
      let(:required_checks) { ['integration_tests'] }

      context 'when check has passed' do
        let(:integration_test_results) { { 'frontend' => FactoryGirl.build(:unit_test_build, success: true) } }

        it { is_expected.to be true }
      end

      context 'when check has not passed' do
        let(:integration_test_results) { { 'frontend' => FactoryGirl.build(:unit_test_build, success: false) } }

        it { is_expected.to be false }
      end
    end

    context 'when unit_tests is selected' do
      let(:required_checks) { ['unit_tests'] }

      context 'when check has passed' do
        let(:unit_test_results) { { 'frontend' => FactoryGirl.build(:unit_test_build, success: true) } }

        it { is_expected.to be true }
      end

      context 'when check has not passed' do
        let(:unit_test_results) { { 'frontend' => FactoryGirl.build(:unit_test_build, success: false) } }

        it { is_expected.to be false }
      end
    end

    context 'when tickets_approval is selected' do
      let(:required_checks) { ['tickets_approval'] }

      context 'when check has passed' do
        let(:tickets) {
          [
            instance_double(Ticket, approved?: true),
            instance_double(Ticket, approved?: true),
          ]
        }

        it { is_expected.to be true }
      end

      context 'when check has not passed' do
        let(:tickets) {
          [
            instance_double(Ticket, approved?: false),
            instance_double(Ticket, approved?: true),
          ]
        }

        it { is_expected.to be false }
      end
    end

    context 'when qa_approval is selected' do
      let(:required_checks) { ['qa_approval'] }

      context 'when check has passed' do
        let(:qa_submissions) { [QaSubmission.new(accepted: true)] }

        it { is_expected.to be true }
      end

      context 'when check has not passed' do
        let(:qa_submissions) { [QaSubmission.new(accepted: false)] }

        it { is_expected.to be false }
      end
    end

    context 'when repo_owner_approval is selected' do
      let(:required_checks) { ['repo_owner_approval'] }

      context 'when check has passed' do
        let(:release_exception) { ReleaseException.new(approved: true) }

        it { is_expected.to be true }
      end

      context 'when check has not passed' do
        let(:release_exception) { ReleaseException.new(approved: false) }

        it { is_expected.to be false }
      end
    end

    context 'when multiple checks are selected' do
      let(:required_checks) { %w(integration_tests unit_tests tickets_approval) }

      context 'when all checks have passed' do
        let(:integration_test_results) { { 'frontend' => FactoryGirl.build(:unit_test_build, success: true) } }
        let(:unit_test_results) { { 'frontend' => FactoryGirl.build(:unit_test_build, success: true) } }
        let(:tickets) {
          [
            instance_double(Ticket, approved?: true),
            instance_double(Ticket, approved?: true),
          ]
        }

        it { is_expected.to be true }
      end

      context 'when some check has not passed' do
        let(:integration_test_results) { { 'frontend' => FactoryGirl.build(:unit_test_build, success: true) } }
        let(:unit_test_results) { { 'frontend' => FactoryGirl.build(:unit_test_build, success: false) } }
        let(:tickets) {
          [
            instance_double(Ticket, approved?: false),
            instance_double(Ticket, approved?: true),
          ]
        }

        it { is_expected.to be false }
      end
    end
  end

  describe '#approved_path' do
    subject { FeatureReviewWithStatuses.new(feature_review, tickets: tickets).approved_path }

    let(:feature_review) {
      instance_double(
        FeatureReview,
        base_path: '/feature_reviews',
        query_hash: { 'apps' => apps },
        app_versions: apps,
        app_names: app_names,
        versions: apps.values,
      )
    }

    context 'when Feature Review is authorised' do
      let(:approval_time) { Time.parse('2013-09-05 14:56:52 UTC') }
      let(:tickets) {
        [
          instance_double(Ticket, authorised?: true, approved?: true, approved_at: approval_time),
          instance_double(Ticket, authorised?: true, approved?: true, approved_at: approval_time - 1.hour),
        ]
      }

      it 'returns the path as at the latest approval time' do
        expect(subject).to eq(
          '/feature_reviews?apps%5Bapp1%5D=xxx&apps%5Bapp2%5D=yyy'\
          '&time=2013-09-05+14%3A56%3A52+UTC',
        )
      end
    end

    context 'when Feature Review is not authorised' do
      let(:tickets) { [instance_double(Ticket, authorised?: false)] }

      it { is_expected.to be_nil }
    end
  end
end
