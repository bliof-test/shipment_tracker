require 'rails_helper'
require 'feature_review_with_statuses'

RSpec.describe FeatureReviewWithStatuses do
  let(:tickets) { double(:tickets) }
  let(:builds) { double(:builds) }
  let(:deploys) { double(:deploys) }
  let(:qa_submission) { double(:qa_submission) }
  let(:uatest) { double(:uatest) }
  let(:apps) { { 'app1' => 'xxx', 'app2' => 'yyy' } }

  let(:uat_url) { 'http://uat.com' }
  let(:feature_review) {
    instance_double(FeatureReview, uat_url: uat_url, app_versions: apps, versions: apps.values)
  }
  let(:query_time) { Time.parse('2014-08-10 14:40:48 UTC') }

  subject(:decorator) {
    FeatureReviewWithStatuses.new(
      feature_review,
      builds: builds,
      deploys: deploys,
      qa_submission: qa_submission,
      tickets: tickets,
      uatest: uatest,
      at: query_time,
    )
  }

  it 'returns #builds, #deploys, #qa_submission, #tickets, #uatest and #time as initialized' do
    expect(decorator.builds).to eq(builds)
    expect(decorator.deploys).to eq(deploys)
    expect(decorator.qa_submission).to eq(qa_submission)
    expect(decorator.tickets).to eq(tickets)
    expect(decorator.uatest).to eq(uatest)
    expect(decorator.time).to eq(query_time)
  end

  context 'when initialized without builds, deploys, qa_submission, tickets, uatest and time' do
    let(:decorator) { described_class.new(feature_review) }

    it 'returns default values for #builds, #deploys, #qa_submission, #tickets, #uatest and #time' do
      expect(decorator.builds).to eq({})
      expect(decorator.deploys).to eq([])
      expect(decorator.qa_submission).to eq(nil)
      expect(decorator.tickets).to eq([])
      expect(decorator.uatest).to eq(nil)
      expect(decorator.time).to eq(nil)
    end
  end

  it 'delegates unknown messages to the feature_review' do
    expect(decorator.uat_url).to eq(feature_review.uat_url)
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

  describe '#build_status' do
    context 'when all builds pass' do
      let(:builds) do
        {
          'frontend' => Build.new(success: true),
          'backend'  => Build.new(success: true),
        }
      end

      it 'returns :success' do
        expect(decorator.build_status).to eq(:success)
      end

      context 'but some builds are missing' do
        let(:builds) do
          {
            'frontend' => Build.new(success: true),
            'backend'  => Build.new,
          }
        end

        it 'returns nil' do
          expect(decorator.build_status).to eq(nil)
        end
      end
    end

    context 'when any of the builds fails' do
      let(:builds) do
        {
          'frontend' => Build.new(success: false),
          'backend'  => Build.new(success: true),
        }
      end

      it 'returns :failure' do
        expect(decorator.build_status).to eq(:failure)
      end
    end

    context 'when there are no builds' do
      let(:builds) { {} }

      it 'returns nil' do
        expect(decorator.build_status).to be nil
      end
    end
  end

  describe '#deploy_status' do
    context 'when all deploys are correct' do
      let(:deploys) do
        [
          Deploy.new(correct: true),
        ]
      end

      it 'returns :success' do
        expect(decorator.deploy_status).to eq(:success)
      end
    end

    context 'when any deploy is not correct' do
      let(:deploys) do
        [
          Deploy.new(correct: true),
          Deploy.new(correct: false),
        ]
      end

      it 'returns :failure' do
        expect(decorator.deploy_status).to eq(:failure)
      end
    end

    context 'when there are no deploys' do
      let(:deploys) { [] }

      it 'returns nil' do
        expect(decorator.deploy_status).to be nil
      end
    end
  end

  describe '#qa_status' do
    context 'when QA submission is accepted' do
      let(:qa_submission) { QaSubmission.new(accepted: true) }

      it 'returns :success' do
        expect(decorator.qa_status).to eq(:success)
      end
    end

    context 'when QA submission is rejected' do
      let(:qa_submission) { QaSubmission.new(accepted: false) }

      it 'returns :failure' do
        expect(decorator.qa_status).to eq(:failure)
      end
    end

    context 'when QA submission is missing' do
      let(:qa_submission) { nil }

      it 'returns nil' do
        expect(decorator.qa_status).to be nil
      end
    end
  end

  describe '#uatest_status' do
    context 'when User Acceptance Tests have passed' do
      let(:uatest) { Uatest.new(success: true) }

      it 'returns :success' do
        expect(decorator.uatest_status).to eq(:success)
      end
    end

    context 'when User Acceptance Tests have failed' do
      let(:uatest) { Uatest.new(success: false) }

      it 'returns :failure' do
        expect(decorator.uatest_status).to eq(:failure)
      end
    end

    context 'when User Acceptance Tests are missing' do
      let(:uatest) { nil }

      it 'returns nil' do
        expect(decorator.uatest_status).to be nil
      end
    end
  end

  describe '#summary_status' do
    context 'when status of deploys, builds, and QA submission are success' do
      let(:builds) { { 'frontend' => Build.new(success: true) } }
      let(:deploys) { [Deploy.new(correct: true)] }
      let(:qa_submission) { QaSubmission.new(accepted: true) }

      it 'returns :success' do
        expect(decorator.summary_status).to eq(:success)
      end
    end

    context 'when any status of deploys, builds, or QA submission is failed' do
      let(:builds) { { 'frontend' => Build.new(success: true) } }
      let(:deploys) { [Deploy.new(correct: true)] }
      let(:qa_submission) { QaSubmission.new(accepted: false) }

      it 'returns :failure' do
        expect(decorator.summary_status).to eq(:failure)
      end
    end

    context 'when no status is a failure but at least one is a warning' do
      let(:builds) { { 'frontend' => Build.new } }
      let(:deploys) { [Deploy.new(correct: true)] }
      let(:qa_submission) { QaSubmission.new(accepted: true) }

      it 'returns nil' do
        expect(decorator.summary_status).to be(nil)
      end
    end
  end

  describe '#authorised?' do
    subject { FeatureReviewWithStatuses.new(feature_review, tickets: tickets).authorised? }

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
          instance_double(Ticket, approved?: false),
          instance_double(Ticket, approved?: true),
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
  end

  describe '#approved_at' do
    subject { FeatureReviewWithStatuses.new(feature_review, tickets: tickets).approved_at }

    let(:approval_time) { Time.current }

    context 'when all associated tickets are approved' do
      let(:tickets) {
        [
          instance_double(Ticket, approved?: true, approved_at: approval_time),
          instance_double(Ticket, approved?: true, approved_at: approval_time - 1.hour),
        ]
      }

      it 'returns the approval time of the ticket that was approved last' do
        expect(subject).to eq(approval_time)
      end
    end

    context 'when any associated tickets are not approved' do
      let(:tickets) {
        [
          instance_double(Ticket, approved?: false, approved_at: nil),
          instance_double(Ticket, approved?: true, approved_at: approval_time),
        ]
      }

      it { is_expected.to be_nil }
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

  describe '#approved_path' do
    subject { FeatureReviewWithStatuses.new(feature_review, tickets: tickets).approved_path }

    let(:feature_review) {
      instance_double(
        FeatureReview,
        base_path: '/feature_reviews',
        query_hash: { 'apps' => apps, 'uat_url' => 'http://uat.com' },
        app_versions: apps,
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
          '&time=2013-09-05+14%3A56%3A52+UTC'\
          '&uat_url=http%3A%2F%2Fuat.com',
        )
      end
    end

    context 'when Feature Review is not authorised' do
      let(:tickets) { [instance_double(Ticket, authorised?: false)] }

      it { is_expected.to be_nil }
    end
  end
end
