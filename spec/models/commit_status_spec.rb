# frozen_string_literal: true

require 'rails_helper'
require 'commit_status'

RSpec.describe CommitStatus do
  before do
    stub_const('ShipmentTracker::GITHUB_REPO_STATUS_WRITE_TOKEN', 'token')
    allow(GithubClient).to receive(:new).and_return(client)

    repository1     = instance_double(GitRepository, get_dependent_commits: [])
    repository_repo = instance_double(GitRepository, get_dependent_commits: [])

    allow_any_instance_of(GitRepositoryLoader).to receive(:load).with('app1').and_return(repository1)
    allow_any_instance_of(GitRepositoryLoader).to receive(:load).with('repo').and_return(repository_repo)
  end

  let(:client) { instance_double(GithubClient) }
  let(:ticket_repository) { instance_double(Repositories::TicketRepository) }
  let(:exception_repository) { instance_double(Repositories::ReleaseExceptionRepository) }

  describe '#update' do
    before do
      allow(Repositories::TicketRepository).to receive(:new).and_return(ticket_repository)
      allow(ticket_repository).to receive(:tickets_for_versions).and_return(tickets)

      allow(Repositories::ReleaseExceptionRepository).to receive(:new).and_return(exception_repository)
      allow(exception_repository).to receive(:release_exception_for).and_return(nil)

      allow(client).to receive(:last_status_for).with(any_args)
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

          CommitStatus.new(full_repo_name: 'owner/app1', sha: 'abc').update
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

          CommitStatus.new(full_repo_name: 'owner/repo', sha: 'abc').update
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
            target_url: 'https://localhost/?q=abc',
          )

          CommitStatus.new(full_repo_name: 'owner/app1', sha: 'abc').update
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
            target_url: 'https://localhost/?q=abc',
          )

          CommitStatus.new(full_repo_name: 'owner/app1', sha: 'abc').update
        end
      end
    end

    context 'when no Feature Review exists' do
      before do
        deploy_repository = instance_double(Repositories::DeployRepository)
        allow(Repositories::DeployRepository).to receive(:new).and_return(deploy_repository)
        allow(deploy_repository).to receive(:last_staging_deploy_for_versions).and_return(deploy)
      end

      let(:deploy) { nil }
      let(:tickets) { [] }

      context 'when a release exception is present' do
        before do
          release_exception = ReleaseException.new(
            approved: true,
            path: '/feature_reviews?apps%5Brepo%5D=abc123',
          )
          allow(exception_repository).to receive(:release_exception_for).and_return(release_exception)
        end

        it 'posts status "success" with description and link to a Feature Review' do
          expect(client).to receive(:create_status).with(
            repo: 'owner/repo',
            sha: 'abc123',
            state: 'success',
            description: 'Approved Feature Review found',
            target_url: 'https://localhost/feature_reviews?apps%5Brepo%5D=abc123',
          )

          CommitStatus.new(full_repo_name: 'owner/repo', sha: 'abc123').update
        end
      end

      it 'posts status "failure" with description and link to create a Feature Review' do
        expect(client).to receive(:create_status).with(
          repo: 'owner/repo',
          sha: 'abc123',
          state: 'failure',
          description: "No Feature Review found. Click 'Details' to create one.",
          target_url: 'https://localhost/feature_reviews?apps%5Brepo%5D=abc123',
        )

        CommitStatus.new(full_repo_name: 'owner/repo', sha: 'abc123').update
      end

      context 'when there is a staging deploy for the software version under review' do
        let(:deploy) { instance_double(Deploy, server: 'staging.com') }

        it 'includes the UAT URL in the link' do
          expect(client).to receive(:create_status).with(
            repo: 'owner/repo',
            sha: 'abc123',
            state: 'failure',
            description: "No Feature Review found. Click 'Details' to create one.",
            target_url: 'https://localhost/feature_reviews?apps%5Brepo%5D=abc123',
          )

          CommitStatus.new(full_repo_name: 'owner/repo', sha: 'abc123').update
        end
      end
    end

    describe 'reduced status updates' do
      let(:tickets) {
        [
          Ticket.new(
            paths: [feature_review_path(app1: 'abc')],
            status: 'In Progress',
          ),
        ]
      }

      it 'will update the github status if there is a change in the status state' do
        expect(client).to receive(:last_status_for).with(
          repo: 'owner/app1',
          sha: 'abc',
        ).and_return(double('github_response', state: 'failure', description: 'Awaiting approval for Feature Review'))

        expect(client).to receive(:create_status).with(
          hash_including(
            state: 'pending',
            description: 'Awaiting approval for Feature Review',
          ),
        )

        CommitStatus.new(full_repo_name: 'owner/app1', sha: 'abc').update
      end

      it 'will update the github status if there is a change in the status description' do
        expect(client).to receive(:last_status_for).with(
          repo: 'owner/app1',
          sha: 'abc',
        ).and_return(double('github_response', state: 'pending', description: 'Searching for Feature Review'))

        expect(client).to receive(:create_status).with(
          hash_including(
            state: 'pending',
            description: 'Awaiting approval for Feature Review',
          ),
        )

        CommitStatus.new(full_repo_name: 'owner/app1', sha: 'abc').update
      end

      it 'will not try to update the github status if there is no change' do
        expect(client).to receive(:last_status_for).with(
          repo: 'owner/app1',
          sha: 'abc',
        ).and_return(double('github_response', state: 'pending', description: 'Awaiting approval for Feature Review'))

        expect(client).not_to receive(:create_status)

        CommitStatus.new(full_repo_name: 'owner/app1', sha: 'abc').update
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

      CommitStatus.new(full_repo_name: 'owner/repo', sha: 'abc123').reset
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

      CommitStatus.new(full_repo_name: 'owner/repo', sha: 'abc123').error
    end
  end

  describe '#not_found' do
    it 'posts status "error" with description and no link' do
      expect(client).to receive(:create_status).with(
        repo: 'owner/repo',
        sha: 'abc123',
        state: 'failure',
        description: "No Feature Review found. Click 'Details' to create one.",
        target_url: 'https://localhost/feature_reviews?apps%5Brepo%5D=abc123',
      )

      CommitStatus.new(full_repo_name: 'owner/repo', sha: 'abc123').not_found
    end
  end

  describe '#last_status' do
    it 'requests status for the given repository and SHA' do
      expect(client).to receive(:last_status_for).with(
        repo: 'owner/repo',
        sha: 'abc123',
      )

      CommitStatus.new(full_repo_name: 'owner/repo', sha: 'abc123').last_status
    end
  end
end
