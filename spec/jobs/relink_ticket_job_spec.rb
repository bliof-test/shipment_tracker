# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RelinkTicketJob do
  include ActiveJob::TestHelper

  describe '#perform' do
    subject(:job) {
      described_class.perform_later(
        full_repo_name: repository,
        before_sha: before_sha,
        after_sha: after_sha,
      )
    }

    let(:repository) { 'owner/app1' }
    let(:before_sha) { 'abc1234' }
    let(:after_sha) { 'def1234' }

    let(:ticket_repo) { instance_double(Repositories::TicketRepository, tickets_for_versions: tickets) }
    let(:git_repo_loader) { instance_double(GitRepositoryLoader, load: git_repo) }
    let(:git_repo) { instance_double(GitRepository, commit_on_master?: on_master) }
    let(:on_master) { false }
    let(:tickets) { [double] }
    let(:github_status_url) { "https://api.github.com/repos/#{repository}/statuses/#{after_sha}" }

    before do
      git_repository_location = instance_double(GitRepositoryLocation, update: nil)
      allow(GitRepositoryLocation).to receive(:find_by_full_repo_name).and_return(git_repository_location)
      allow(Repositories::TicketRepository).to receive(:new).and_return(ticket_repo)
      allow(GitRepositoryLoader).to receive(:from_rails_config) { git_repo_loader }
      stub_request(:post, github_status_url)
    end

    context 'when there are no previously linked tickets' do
      let(:tickets) { [] }

      it 'does not post a JIRA comment' do
        expect(JiraClient).not_to receive(:post_comment)

        perform_enqueued_jobs { job }
      end

      it 'posts a "failure" commit status to GitHub' do
        perform_enqueued_jobs { job }

        expect(WebMock).to have_requested(:post, github_status_url).with(
          :body => hash_including({state: "failure"})
        ).once
      end
    end

    context 'when there are previously linked tickets' do
      let(:repository) { 'owner/app1' }

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
              feature_review_path(app1: 'abc5678'),
              feature_review_path(app1: 'abc1234'),
            ]
          }

          let(:paths_issue2) {
            [
              feature_review_path(app1: 'bcd1234'),
              feature_review_path(app1: 'ced1234'),
            ]
          }

          it 'posts linking comment to JIRA with relevant Feature Review' do
            expect(JiraClient).to receive(:post_comment).once.with(
              tickets.first.key,
              "[Feature ready for review|#{feature_review_url(app1: 'def1234')}]",
            )

            perform_enqueued_jobs { job }
          end
        end

        context 'with multiple apps per Feature Review' do
          let(:repository) { 'owner/app2' }

          let(:paths_issue1) {
            [
              feature_review_path(app1: 'bcd1234', app2: 'abc1234'),
              feature_review_path(app3: 'ccp1234', app4: 'ced1234'),
            ]
          }

          let(:paths_issue2) {
            [
              feature_review_path(app2: 'abc1234', app5: 'fdc1234'),
            ]
          }

          it 'posts linking comment to JIRA with relevant Feature Review' do
            expect(JiraClient).to receive(:post_comment).once.ordered.with(
              tickets.first.key,
              "[Feature ready for review|#{feature_review_url(app1: 'bcd1234', app2: 'def1234')}]",
            )
            expect(JiraClient).to receive(:post_comment).once.ordered.with(
              tickets.second.key,
              "[Feature ready for review|#{feature_review_url(app2: 'def1234', app5: 'fdc1234')}]",
            )

            perform_enqueued_jobs { job }
          end
        end
      end
    end

    context 'when the linking fails for a ticket' do
      let(:repository) { 'owner/app1' }
      let(:commit_status) { instance_double(CommitStatus, not_found: nil, reset: nil) }

      let(:tickets) {
        [
          instance_double(Ticket, key: 'ISSUE-1', paths: paths_issue1),
          instance_double(Ticket, key: 'ISSUE-2', paths: paths_issue2),
        ]
      }

      let(:paths_issue1) {
        [
          feature_review_path(app1: 'abc1234'),
          feature_review_path(app1: 'ced1234'),
        ]
      }

      let(:paths_issue2) {
        [
          feature_review_path(app1: 'abc1234'),
          feature_review_path(app1: 'caa1234'),
        ]
      }

      it 'rescues and continues to link other tickets' do
        allow_any_instance_of(CommitStatus).to receive(:error)
        allow(JiraClient).to receive(:post_comment).with(tickets.first.key, anything)
                                                   .and_raise(JiraClient::InvalidKeyError)

        expect(JiraClient).to receive(:post_comment).with(tickets.second.key, anything)

        perform_enqueued_jobs { job }
      end

      it 'posts "error" status to GitHub on InvalidKeyError' do
        allow(JiraClient).to receive(:post_comment).and_raise(JiraClient::InvalidKeyError)

        expect_any_instance_of(CommitStatus).to receive(:error).once

        perform_enqueued_jobs { job }
      end

      it 'posts "error" status to GitHub on any other error' do
        allow(JiraClient).to receive(:post_comment).and_raise

        allow(CommitStatus).to receive(:new).with(
          full_repo_name: 'owner/app1',
          sha: 'def1234',
        ).and_return(commit_status)
        expect(commit_status).to receive(:error).once

        perform_enqueued_jobs { job }
      end
    end
  end
end
