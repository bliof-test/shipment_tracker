require 'rails_helper'
require 'handle_push_event'

RSpec.describe HandlePushEvent do
  describe 'updating remote head' do
    it 'updates the corresponding repository location' do
      github_payload = instance_double(
        Payloads::Github,
        full_repo_name: 'owner/repo',
        before_sha: 'abc123',
        after_sha: 'def456',
      )

      git_repository_location = instance_double(GitRepositoryLocation)
      allow(GitRepositoryLocation).to receive(:find_by_full_repo_name).and_return(git_repository_location)

      expect(git_repository_location).to receive(:update).with(remote_head: 'def456')
      HandlePushEvent.run(github_payload)
    end

    it 'fails when repo not found' do
      github_payload = instance_double(Payloads::Github, full_repo_name: 'owner/repo', after_sha: 'abc123')

      allow(GitRepositoryLocation).to receive(:find_by_full_repo_name).and_return(nil)

      result = HandlePushEvent.run(github_payload)
      expect(result).to be_failure
    end
  end

  describe 'relinking tickets' do
    before do
      git_repository_location = instance_double(GitRepositoryLocation, update: nil)
      allow(GitRepositoryLocation).to receive(:find_by_full_repo_name).and_return(git_repository_location)
      allow(Repositories::TicketRepository).to receive(:new).and_return(ticket_repo)
    end

    let(:ticket_repo) { instance_double(Repositories::TicketRepository, tickets_for_versions: tickets) }

    context 'when there are no previously linked tickets' do
      let(:tickets) { [] }

      it 'does nothing' do
        expect(JiraClient).not_to receive(:post_comment)

        github_payload = instance_double(
          Payloads::Github,
          full_repo_name: 'owner/repo',
          before_sha: 'abc123',
          after_sha: 'def456',
        )

        HandlePushEvent.run(github_payload)
      end
    end

    context 'when there are previously linked tickets' do
      let(:tickets) {
        [
          instance_double(Ticket, key: 'ISSUE-1', paths: paths_issue1),
          instance_double(Ticket, key: 'ISSUE-2', paths: paths_issue2),
        ]
      }

      context 'with multiple Feature Reviews' do
        context 'with one app per Feature Review' do
          let(:paths_issue1) {
            [
              feature_review_path(app1: 'abc'),
              feature_review_path(app1: 'def'),
            ]
          }

          let(:paths_issue2) {
            [
              feature_review_path(app1: 'uvw'),
              feature_review_path(app1: 'xyz'),
            ]
          }

          it 'posts linking comment to JIRA with relevant Feature Review' do
            expect(JiraClient).to receive(:post_comment).once.with(
              tickets.first.key,
              "[Feature ready for review|#{feature_review_url(app1: 'ghi')}]",
            )

            github_payload = instance_double(
              Payloads::Github,
              full_repo_name: 'owner/app1',
              before_sha: 'def',
              after_sha: 'ghi',
            )
            HandlePushEvent.run(github_payload)
          end
        end

        context 'with multiple apps per Feature Review' do
          let(:paths_issue1) {
            [
              feature_review_path(app1: 'abc', app2: 'def'),
              feature_review_path(app3: 'ghi', app4: 'klm'),
            ]
          }

          let(:paths_issue2) {
            [
              feature_review_path(app2: 'def', app5: 'uvw'),
            ]
          }

          it 'posts linking comment to JIRA with relevant Feature Review' do
            expect(JiraClient).to receive(:post_comment).once.ordered.with(
              tickets.first.key,
              "[Feature ready for review|#{feature_review_url(app1: 'abc', app2: 'xyz')}]",
            )
            expect(JiraClient).to receive(:post_comment).once.ordered.with(
              tickets.second.key,
              "[Feature ready for review|#{feature_review_url(app2: 'xyz', app5: 'uvw')}]",
            )

            github_payload = instance_double(
              Payloads::Github,
              full_repo_name: 'owner/app2',
              before_sha: 'def',
              after_sha: 'xyz',
            )
            HandlePushEvent.run(github_payload)
          end
        end
      end
    end

    context 'when the linking fails for a ticket' do
      let(:tickets) {
        [
          instance_double(Ticket, key: 'ISSUE-1', paths: paths_issue1),
          instance_double(Ticket, key: 'ISSUE-2', paths: paths_issue2),
        ]
      }

      let(:paths_issue1) {
        [
          feature_review_path(app1: 'abc'),
          feature_review_path(app1: 'def'),
        ]
      }

      let(:paths_issue2) {
        [
          feature_review_path(app1: 'abc'),
          feature_review_path(app1: 'xyz'),
        ]
      }

      it 'should rescue and continue to link other tickets' do
        allow(JiraClient).to receive(:post_comment).with(tickets.first.key, anything)
          .and_raise(JiraClient::InvalidKeyError)

        github_payload = instance_double(
          Payloads::Github,
          full_repo_name: 'owner/app1',
          before_sha: 'abc',
          after_sha: 'uvw',
        )

        expect(JiraClient).to receive(:post_comment).with(tickets.second.key, anything)

        HandlePushEvent.run(github_payload)
      end
    end
  end
end
