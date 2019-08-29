# frozen_string_literal: true

require 'spec_helper'
require 'payloads/github'

RSpec.describe Payloads::Github do
  describe '#before_sha' do
    context 'when payload contains "before" data (push event)' do
      it 'returns sha' do
        payload = Payloads::Github.new('before' => 'abc123')

        expect(payload.before_sha).to eq('abc123')
      end
    end

    context 'when payload does not contain "before" data' do
      it 'returns nil' do
        payload = Payloads::Github.new('some_key' => 'some_value')

        expect(payload.before_sha).to be_nil
      end
    end
  end

  describe '#after_sha' do
    context 'when payload contains "after" data (push event)' do
      it 'returns sha' do
        payload = Payloads::Github.new('after' => 'abc123')

        expect(payload.after_sha).to eq('abc123')
      end
    end

    context 'when payload does not contain "after" data' do
      it 'returns nil' do
        payload = Payloads::Github.new('some_key' => 'some_value')

        expect(payload.after_sha).to be_nil
      end
    end
  end

  describe '#base_repo_url' do
    context 'with pull_request data' do
      it 'returns html url' do
        data = {
          'repository' => {
            'html_url' => 'https://github.com/foo/bar',
          },
        }
        payload = Payloads::Github.new(data)

        expect(payload.base_repo_url).to eq('https://github.com/foo/bar')
      end
    end

    context 'with no pull_request data' do
      it 'returns nil' do
        payload = Payloads::Github.new('some_key' => 'some_value')

        expect(payload.base_repo_url).to be_nil
      end
    end
  end

  describe '#head_sha' do
    context 'with pull_request data' do
      it 'returns sha' do
        data = { 'head_commit' => {
          'id' => 'abc123',
        } }
        payload = Payloads::Github.new(data)

        expect(payload.head_sha).to eq('abc123')
      end
    end

    context 'with no pull_request data' do
      it 'returns nil' do
        payload = Payloads::Github.new('some_key' => 'some_value')

        expect(payload.head_sha).to be_nil
      end
    end
  end

  describe '#full_repo_name' do
    context 'with repository data' do
      it 'returns the full repository name' do
        data = { 'repository' => { 'full_name' => 'owner/repo' } }
        payload = Payloads::Github.new(data)

        expect(payload.full_repo_name).to eq('owner/repo')
      end
    end

    context 'with no repository data' do
      it 'returns nil' do
        payload = Payloads::Github.new('some_key' => 'some_value')

        expect(payload.full_repo_name).to be_nil
      end
    end
  end

  describe '#push_annotated_tag?' do
    context 'when payload has insufficient data' do
      it 'returns false' do
        payload = Payloads::Github.new('some_key' => 'some_value')

        expect(payload.push_annotated_tag?).to be false
      end
    end

    context 'when payload is for a commit' do
      it 'returns false' do
        data = { 'ref' => 'refs/heads/some-branch', 'base_ref' => nil }
        payload = Payloads::Github.new(data)

        expect(payload.push_annotated_tag?).to be false
      end
    end

    context 'when payload is for a lightweight tag' do
      it 'returns false' do
        data = { 'ref' => 'refs/tags/lightweight-tag', 'base_ref' => 'refs/heads/master' }
        payload = Payloads::Github.new(data)

        expect(payload.push_annotated_tag?).to be false
      end
    end

    context 'when payload is for an annotated tag' do
      it 'returns true' do
        data = { 'ref' => 'refs/tags/annotated-tag', 'base_ref' => nil }
        payload = Payloads::Github.new(data)

        expect(payload.push_annotated_tag?).to be true
      end
    end
  end

  describe '#push_to_master?' do
    context 'when payload references master branch' do
      it 'returns true' do
        payload = Payloads::Github.new('ref' => 'refs/heads/master')

        expect(payload.push_to_master?).to be true
      end
    end

    context 'when payload does not reference master branch' do
      it 'returns false' do
        payload = Payloads::Github.new('ref' => 'refs/heads/topic-branch')

        expect(payload.push_to_master?).to be false
      end
    end
  end

  describe '#branch_name' do
    it 'returns the branch name' do
      branch_name = 'super-feature'
      payload = Payloads::Github.new('ref' => "refs/heads/#{branch_name}")

      expect(payload.branch_name).to eq(branch_name)
    end

    context('given a branch name containing slashes') do
      it 'returns the branch name' do
        branch_name = 'epic-name/super-feature'
        payload = Payloads::Github.new('ref' => "refs/heads/#{branch_name}")

        expect(payload.branch_name).to eq(branch_name)
      end
    end
  end
end
