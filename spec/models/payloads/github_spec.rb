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

  describe '#head_sha' do
    context 'with pull_request data' do
      it 'returns sha' do
        data = { 'head_commit' => {
            'id' => 'abc123'
          }
        }
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
end
