require 'spec_helper'
require 'payloads/github'

RSpec.describe Payloads::Github do
  describe '#head_sha' do
    context 'with pull_request data' do
      it 'returns sha' do
        data = { 'pull_request' => { 'head' => { 'sha' => 'abc123' } } }
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
          'pull_request' => {
            'base' => {
              'repo' => {
                'html_url' => 'https://github.com/foo/bar',
              },
            },
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

  describe '#action' do
    context 'when the payload has an action' do
      it 'returns the action' do
        payload = Payloads::Github.new('action' => 'opened')

        expect(payload.action).to eq('opened')
      end
    end

    context 'when the payload has no action' do
      it 'returns nil' do
        payload = Payloads::Github.new('some_key' => 'some_value')

        expect(payload.action).to be_nil
      end
    end
  end
end
