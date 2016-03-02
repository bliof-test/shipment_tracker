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
        github_payload = instance_double(
          Payloads::Github,
          full_repo_name: 'owner/repo',
          before_sha: 'abc123',
          after_sha: 'def456',
        )

        result = HandlePushEvent.run(github_payload)
        expect(result).to be_failure
      end
    end

    context 'when there is one previously linked ticket' do
      let(:tickets) { [instance_double(Ticket, key: 'ISSUE-ID', paths: paths)] }

      context 'with multiple Feature Reviews' do
        context 'with one app per Feature Review' do
          let(:paths) {
            [
              feature_review_path(foo: 'before'),
              feature_review_path(bar: 'unrelated'),
            ]
          }

          it 'posts linking comment to JIRA with relevant Feature Review' do
            expect(JiraClient).to receive(:post_comment).once.with(
              tickets.first.key,
              "[Feature ready for review|#{feature_review_url(foo: 'after')}]",
            )

            github_payload = instance_double(
              Payloads::Github,
              full_repo_name: 'owner/foo',
              before_sha: 'before',
              after_sha: 'after',
            )
            HandlePushEvent.run(github_payload)
          end
        end

        context 'with multiple apps per Feature Review' do
          let(:paths) {
            [
              feature_review_path(foo: 'abc123', bar: 'efg324'),
              feature_review_path(bar: 'bcd123'),
            ]
          }

          it 'posts linking comment to JIRA with relevant Feature Review' do
            expect(JiraClient).to receive(:post_comment).once.with(
              tickets.first.key,
              "[Feature ready for review|#{feature_review_url(foo: 'def456', bar: 'efg324')}]",
            )

            github_payload = instance_double(
              Payloads::Github,
              full_repo_name: 'owner/foo',
              before_sha: 'abc123',
              after_sha: 'def456',
            )
            HandlePushEvent.run(github_payload)
          end
        end
      end
    end
  end
end
