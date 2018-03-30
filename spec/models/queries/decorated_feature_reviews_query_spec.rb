# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Queries::DecoratedFeatureReviewsQuery do
  describe '#get_commit' do
    before do
      repository1 = instance_double(GitRepository, get_dependent_commits: [double(id: 'abc')])
      allow_any_instance_of(GitRepositoryLoader).to receive(:load).with('app1').and_return(repository1)
    end

    context 'when tickets exist for the given commit' do
      let(:tickets) {
        [
          Ticket.new(
            paths: [
              feature_review_path(app1: 'abc', app2: 'def'),
              feature_review_path(app1: 'xyz'),
            ],
            version_timestamps: { 'abc' => 1.hour.ago, 'def' => 1.hour.ago, 'xyz' => 2.hours.ago },
          ),
        ]
      }

      before do
        allow_any_instance_of(Repositories::TicketRepository)
          .to receive(:tickets_for_versions)
          .and_return(tickets)
      end

      it 'returns a decorated feature review with the given tickets' do
        feature_reviews = described_class.new('app1', [GitCommit.new(id: 'abc')]).get
        expect(feature_reviews.first.tickets).to eq(tickets)
      end
    end

    context 'when no tickets exist for the given commit' do
      let(:tickets) { [] }

      context 'when a release exception is present' do
        let(:release_exception) {
          ReleaseException.new(
            approved: true,
            path: '/feature_reviews?apps%5Bapp1%5D=abc',
          )
        }

        before do
          allow_any_instance_of(Repositories::ReleaseExceptionRepository)
            .to receive(:release_exception_for)
            .and_return(release_exception)
        end

        it 'returns a decorated feature review with the given release_exception' do
          feature_reviews = described_class.new('app1', [GitCommit.new(id: 'abc')]).get
          expect(feature_reviews.first.release_exception).to eq(release_exception)
        end
      end

      context 'when no release_exception is present' do
        it 'returns a new feature review' do
          feature_reviews = described_class.new('app1', [GitCommit.new(id: 'abc')]).get
          expect(feature_reviews.first.path).to eq('/feature_reviews?apps%5Bapp1%5D=abc')
          expect(feature_reviews.first.versions).to eq(%w[abc])
        end

        context 'when there is a staging deploy for the software version under review' do
          let(:deploy) { instance_double(Deploy, server: 'uat.com') }

          before do
            allow_any_instance_of(Repositories::DeployRepository)
              .to receive(:last_staging_deploy_for_versions)
              .and_return(deploy)
          end

          it 'includes the UAT URL in the link' do
            feature_reviews = described_class.new('app1', [GitCommit.new(id: 'abc')]).get
            expect(feature_reviews.first.path).to eq('/feature_reviews?apps%5Bapp1%5D=abc')
          end
        end
      end
    end
  end
end
