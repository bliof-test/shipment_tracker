# frozen_string_literal: true

require 'spec_helper'
require 'payloads/github_pull_request'

RSpec.describe Payloads::GithubPullRequest do
  describe '#created?' do
    context 'when payload contains the "opened" action' do
      it 'returns true' do
        payload = described_class.new('action' => 'opened')

        expect(payload.created?).to be true
      end
    end

    context 'when payload does not contain the "opened" action' do
      it 'returns false' do
        payload = described_class.new('action' => 'some_value')

        expect(payload.created?).to be false
      end
    end
  end

  describe '#updated?' do
    context 'when payload contains the "synchronize" action' do
      it 'returns true' do
        payload = described_class.new('action' => 'synchronize')

        expect(payload.updated?).to be true
      end
    end

    context 'when payload does not contain the "synchronize" action' do
      it 'returns false' do
        payload = described_class.new('action' => 'some_value')

        expect(payload.updated?).to be false
      end
    end
  end

  describe '#merged?' do
    context 'when payload contains the "closed" action' do
      let(:data) {
        {
          'action' => 'closed',
          'pull_request' => { 'merged' => merged },
        }
      }

      context 'when merged' do
        let(:merged) { true }

        it 'returns true' do
          payload = described_class.new(data)

          expect(payload.merged?).to be true
        end
      end

      context 'when closed' do
        let(:merged) { false }

        it 'returns false' do
          payload = described_class.new(data)

          expect(payload.merged?).to be false
        end
      end
    end

    context 'when payload does not contain the "closed" action' do
      it 'returns false' do
        payload = described_class.new('action' => 'some_value')

        expect(payload.merged?).to be false
      end
    end
  end

  describe '#merge_commit_sha' do
    context 'when the payload contain the merge commit' do
      it 'returns merge commit' do
        data = { 'pull_request' => { 'merge_commit_sha' => 'def1234' } }
        payload = described_class.new(data)

        expect(payload.merge_commit_sha).to eq 'def1234'
      end
    end

    context 'when the payload does not contain the merge commit' do
      it 'returns nil' do
        payload = described_class.new('pull_request' => { 'some_key' => 'some_value' })

        expect(payload.merge_commit_sha).to be_nil
      end
    end
  end

  describe '#branch_name' do
    context 'when the payload contain the pull request branch name' do
      it 'returns branch name' do
        data = { 'pull_request' => { 'head' => { 'ref' => 'branch-name' } } }
        payload = described_class.new(data)

        expect(payload.branch_name).to eq 'branch-name'
      end
    end

    context 'when the payload does not contain the pull request branch name' do
      it 'returns nil' do
        payload = described_class.new('some_key' => 'some_value')

        expect(payload.branch_name).to be_nil
      end
    end
  end

  describe '#base_branch_master?' do
    context 'when the pull request base branch is "master"' do
      it 'returns true' do
        data = { 'pull_request' => { 'base' => { 'ref' => 'master' } } }
        payload = described_class.new(data)

        expect(payload.base_branch_master?).to be true
      end
    end

    context 'when the pull request base branch is not "master"' do
      it 'returns false' do
        data = { 'pull_request' => { 'base' => { 'ref' => 'foobar' } } }
        payload = described_class.new(data)

        expect(payload.base_branch_master?).to be false
      end
    end
  end

  describe '#before_sha' do
    context 'when payload contains "before" data' do
      it 'returns sha' do
        payload = described_class.new('before' => 'abc123')

        expect(payload.before_sha).to eq('abc123')
      end
    end

    context 'when merged' do
      context 'when payload contains "base sha" data' do
        let(:data) {
          {
            'action' => 'closed',
            'pull_request' => {
              'merged' => true,
              'base' => {
                'sha' => 'abc123',
              },
            },
          }
        }

        it 'returns sha' do
          payload = described_class.new(data)

          expect(payload.before_sha).to eq('abc123')
        end
      end
    end

    context 'when payload does not contain "before" data' do
      it 'returns nil' do
        payload = described_class.new('some_key' => 'some_value')

        expect(payload.before_sha).to be_nil
      end
    end
  end

  describe '#after_sha' do
    context 'when payload contains "after" data' do
      it 'returns sha' do
        payload = described_class.new('after' => 'abc123')

        expect(payload.after_sha).to eq('abc123')
      end
    end

    context 'when merged' do
      context 'when payload contains "merge_commit_sha" data' do
        let(:data) {
          {
            'action' => 'closed',
            'pull_request' => {
              'merged' => true,
              'merge_commit_sha' => 'abc123',
            },
          }
        }

        it 'returns sha' do
          payload = described_class.new(data)

          expect(payload.after_sha).to eq('abc123')
        end
      end
    end

    context 'when payload does not contain "after" data' do
      it 'returns nil' do
        payload = described_class.new('some_key' => 'some_value')

        expect(payload.after_sha).to be_nil
      end
    end
  end

  describe '#head_sha' do
    context 'with pull_request data' do
      it 'returns sha' do
        data = { 'pull_request' => { 'head' => { 'sha' => 'abc123' } } }
        payload = described_class.new(data)

        expect(payload.head_sha).to eq('abc123')
      end
    end

    context 'with no pull_request data' do
      it 'returns nil' do
        payload = described_class.new('some_key' => 'some_value')

        expect(payload.head_sha).to be_nil
      end
    end
  end

  describe '#full_repo_name' do
    context 'with repository data' do
      it 'returns the full repository name' do
        data = { 'pull_request' => { 'base' => { 'repo' => { 'full_name' => 'owner/repo' } } } }
        payload = described_class.new(data)

        expect(payload.full_repo_name).to eq('owner/repo')
      end
    end

    context 'with no repository data' do
      it 'returns nil' do
        payload = described_class.new('some_key' => 'some_value')

        expect(payload.full_repo_name).to be_nil
      end
    end
  end
end
