require 'rails_helper'
require 'pull_request_status'

RSpec.describe PullRequestStatus do
  before do
    stub_const('ShipmentTracker::GITHUB_REPO_STATUS_WRITE_TOKEN', 'token')
    allow(GithubClient).to receive(:new).and_return(client)
  end

  let(:client) { instance_double(GithubClient) }

  describe '#update' do
    before do
      ticket_repository = instance_double(Repositories::TicketRepository)
      allow(Repositories::TicketRepository).to receive(:new).and_return(ticket_repository)
      allow(ticket_repository).to receive(:tickets_for_versions).and_return(tickets)
    end

    context 'when a single Feature Review exists for the relevant commit' do
      context 'when the tickets associated with the Feature Review are authorised' do
        let(:tickets) {
          [
            Ticket.new(
              paths: [
                feature_review_path(app1: 'abc', app2: 'def'),
                feature_review_path(app1: 'xyz'),
              ],
              approved_at: Time.current,
              version_timestamps: { 'abc' => 1.hour.ago, 'def' => 1.hour.ago, 'xyz' => 2.hours.ago },
            ),
          ]
        }

        it 'posts status "success" with description and link to Feature Review' do
          expect(client).to receive(:create_status).with(
            repo: 'owner/app1',
            sha: 'abc',
            state: 'success',
            description: 'Approved Feature Review found',
            target_url: 'https://localhost/feature_reviews?apps%5Bapp1%5D=abc&apps%5Bapp2%5D=def',
          )

          PullRequestStatus.new.update(full_repo_name: 'owner/app1', sha: 'abc')
        end
      end

      context 'when the tickets associated with the Feature Review are not authorised' do
        let(:tickets) {
          [
            Ticket.new(
              paths: [feature_review_path(repo: 'abc')],
              status: 'Done',
              approved_at: 1.hour.ago,
              version_timestamps: { 'abc' => Time.current },
            ),
          ]
        }

        it 'posts status "pending" with description and link to Feature Review' do
          expect(client).to receive(:create_status).with(
            repo: 'owner/repo',
            sha: 'abc',
            state: 'pending',
            description: 'Re-approval required for Feature Review',
            target_url: 'https://localhost/feature_reviews?apps%5Brepo%5D=abc',
          )

          PullRequestStatus.new.update(full_repo_name: 'owner/repo', sha: 'abc')
        end
      end
    end

    context 'when multiple Feature Reviews exist for the relevant commit' do
      context 'when one of the Feature Reviews is authorised' do
        let(:tickets) {
          [
            Ticket.new(
              paths: [feature_review_path(app1: 'abc')],
              status: 'In Progress',
              approved_at: nil,
              version_timestamps: { 'abc' => 1.hour.ago },
            ),
            Ticket.new(
              paths: [feature_review_path(app1: 'abc', app2: 'def')],
              status: 'Done',
              approved_at: Time.current,
              version_timestamps: { 'abc' => 2.hours.ago, 'def' => 1.hour.ago },
            ),
          ]
        }

        it 'posts status "success" with description and link to Feature Review search' do
          expect(client).to receive(:create_status).with(
            repo: 'owner/app1',
            sha: 'abc',
            state: 'success',
            description: 'Approved Feature Review found',
            target_url: 'https://localhost/feature_reviews/search?application=app1&version=abc',
          )

          PullRequestStatus.new.update(full_repo_name: 'owner/app1', sha: 'abc')
        end
      end

      context 'when none of the Feature Reviews are authorised' do
        let(:tickets) {
          [
            Ticket.new(
              paths: [feature_review_path(app1: 'abc', app2: 'def')],
              status: 'In Progress',
            ),
            Ticket.new(
              paths: [feature_review_path(app1: 'abc')],
              status: 'In Progress',
            ),
          ]
        }

        it 'posts status "pending" with description and link to Feature Review search' do
          expect(client).to receive(:create_status).with(
            repo: 'owner/app1',
            sha: 'abc',
            state: 'pending',
            description: 'Awaiting approval for Feature Review',
            target_url: 'https://localhost/feature_reviews/search?application=app1&version=abc',
          )

          PullRequestStatus.new.update(full_repo_name: 'owner/app1', sha: 'abc')
        end
      end
    end

    context 'when no Feature Review exists' do
      before do
        deploy_repository = instance_double(Repositories::DeployRepository)
        allow(Repositories::DeployRepository).to receive(:new).and_return(deploy_repository)
        allow(deploy_repository).to receive(:last_staging_deploy_for_version).and_return(deploy)
      end

      let(:deploy) { nil }
      let(:tickets) { [] }

      it 'posts status "failure" with description and link to create a Feature Review' do
        expect(client).to receive(:create_status).with(
          repo: 'owner/repo',
          sha: 'abc123',
          state: 'failure',
          description: "No Feature Review found. Click 'Details' to create one.",
          target_url: 'https://localhost/feature_reviews?apps%5Brepo%5D=abc123',
        )

        PullRequestStatus.new.update(full_repo_name: 'owner/repo', sha: 'abc123')
      end

      context 'when there is a staging deploy for the software version under review' do
        let(:deploy) { instance_double(Deploy, server: 'uat.com') }

        it 'includes the UAT URL in the link' do
          expect(client).to receive(:create_status).with(
            repo: 'owner/repo',
            sha: 'abc123',
            state: 'failure',
            description: "No Feature Review found. Click 'Details' to create one.",
            target_url: 'https://localhost/feature_reviews?apps%5Brepo%5D=abc123&uat_url=uat.com',
          )

          PullRequestStatus.new.update(full_repo_name: 'owner/repo', sha: 'abc123')
        end
      end
    end
  end

  describe '#reset' do
    it 'posts status "pending" with description and no link' do
      expect(client).to receive(:create_status).with(
        repo: 'owner/repo',
        sha: 'abc123',
        state: 'pending',
        description: 'Searching for Feature Review',
        target_url: nil,
      )

      PullRequestStatus.new.reset(full_repo_name: 'owner/repo', sha: 'abc123')
    end
  end

  describe '#error' do
    it 'posts status "error" with description and no link' do
      expect(client).to receive(:create_status).with(
      repo: 'owner/repo',
      sha: 'abc123',
      state: 'error',
      description: 'Something went wrong while relinking your PR to FR.',
      target_url: nil,
      )

      PullRequestStatus.new.error(full_repo_name: 'owner/repo', sha: 'abc123')
    end
  end

  describe '#not_found' do
    it 'posts status "error" with description and no link' do
      expect(client).to receive(:create_status).with(
      repo: 'owner/repo',
      sha: 'abc123',
      state: 'failure',
      description: "No Feature Review found. Click 'Details' to create one.",
      target_url: nil,
      )

      PullRequestStatus.new.not_found(full_repo_name: 'owner/repo', sha: 'abc123')
    end
  end
end
