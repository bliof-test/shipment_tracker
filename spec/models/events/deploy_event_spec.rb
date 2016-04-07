# frozen_string_literal: true
require 'rails_helper'
require 'events/deploy_event'

RSpec.describe Events::DeployEvent do
  subject { Events::DeployEvent.new(details: payload) }

  context 'given a custom payload' do
    let(:payload) {
      {
        'app_name' => 'some_app',
        'servers' => ['prod1.example.com', 'prod2.example.com'],
        'version' => '1abcabcabcabcabcabcabcabcabcabcabcabcabc',
        'deployed_by' => 'bob',
        'locale' => 'us',
        'environment' => 'staging',
      }
    }

    it 'returns the correct values' do
      expect(subject.app_name).to eq('some_app')
      expect(subject.server).to eq('prod1.example.com')
      expect(subject.version).to eq('1abcabcabcabcabcabcabcabcabcabcabcabcabc')
      expect(subject.deployed_by).to eq('bob')
      expect(subject.environment).to eq('staging')
      expect(subject.locale).to eq('us')
    end

    context 'when the payload does not have locale' do
      before do
        payload.delete('locale')
      end

      it 'uses default locale "gb"' do
        expect(subject.locale).to eq('gb')
      end
    end

    context 'when the payload contains uppercased values' do
      let(:payload) {
        {
          'app_name' => 'AwesomeApp',
          'servers' => ['PROD.example.com'],
          'version' => '1abcabcabcabcabcabcabcabcabcabcabcabcabc',
          'deployed_by' => 'Johnny Five',
          'locale' => 'GB',
          'environment' => 'UAT',
        }
      }

      it 'downcases the app_name, environment, and locale' do
        expect(subject.app_name).to eq('awesomeapp')
        expect(subject.environment).to eq('uat')
        expect(subject.locale).to eq('gb')

        expect(subject.server).to eq('PROD.example.com')
        expect(subject.version).to eq('1abcabcabcabcabcabcabcabcabcabcabcabcabc')
        expect(subject.deployed_by).to eq('Johnny Five')
      end
    end

    context 'when the payload contains a short SHA' do
      before do
        payload['version'] = '1abc'

        commit = double(GitCommit, id: '1abcabcabcabcabcabcabcabcabcabcabcabcabc')
        git_repo = double(GitRepository, commit_for_version: commit)
        allow_any_instance_of(GitRepositoryLoader).to receive(:load).and_return(git_repo)
      end

      it 'expands to full SHA' do
        expect(subject.version).to eq('1abcabcabcabcabcabcabcabcabcabcabcabcabc')
      end
    end

    context 'when the payload is missing the version' do
      before do
        payload['version'] = nil
      end

      it 'returns nil for the version' do
        expect(subject.version).to be_nil
      end
    end

    context 'when the payload contains a gibberish version longer than 40 chars' do
      before do
        payload['version'] = 'abc' * 20
      end

      it 'returns nil for the version' do
        expect(subject.version).to be_nil
      end
    end

    context 'when the payload contains deprecated params' do
      let(:payload) { { 'server' => 'uat.example.com' } }

      it 'returns the correct values' do
        expect(subject.server).to eq('uat.example.com')
      end
    end
  end

  context 'given a Heroku payload' do
    let(:payload) {
      {
        'app' => 'us-nameless-forest-uat',
        'app_uuid' => '8d1e4aff-eac8-4ced-90c8-bf97f8334a4c',
        'git_log' => '',
        'head' => '2beae04',
        'head_long' => '2beae049a22c053883661771551f914d2d3de6e5',
        'prev_head' => '7650eb713bcaae1e4c03637eae2e333fc4fb5a74',
        'release' => 'v189',
        'url' => 'http://us-nameless-forest-uat.herokuapp.com',
        'user' => 'user@example.com',
      }
    }

    it 'returns the correct values' do
      expect(subject.app_name).to eq('us-nameless-forest')
      expect(subject.deployed_by).to eq('user@example.com')
      expect(subject.environment).to eq('uat')
      expect(subject.locale).to eq('us')
      expect(subject.server).to eq('http://us-nameless-forest-uat.herokuapp.com')
      expect(subject.version).to eq('2beae049a22c053883661771551f914d2d3de6e5')
    end

    context 'when the app name does not have the environment in lowercase' do
      before do
        payload['app'] = 'nameless-forest-UAT'
      end

      it 'downcases the environment' do
        expect(subject.environment).to eq('uat')
      end
    end

    context 'when the app name does not have the locale prefix in lowercase' do
      before do
        payload['app'] = 'GB-nameless-forest'
      end

      it 'downcases the environment' do
        expect(subject.locale).to eq('gb')
      end
    end

    context 'when the app name does not include the environment at the end' do
      before do
        payload['app'] = 'nameless-forest'
      end

      it 'sets the environment to nil' do
        expect(subject.environment).to be nil
      end
    end

    context 'when the app name does not include the locale prefix' do
      before do
        payload['app'] = 'nameless-forest'
      end

      it 'sets the environment to nil' do
        expect(subject.locale).to eq('us')
      end
    end
  end

  context 'given an unexpected payload' do
    let(:payload) { { 'some' => 'value' } }

    it 'returns the correct values' do
      expect(subject.app_name).to be nil
      expect(subject.server).to be nil
      expect(subject.version).to be nil
      expect(subject.deployed_by).to be nil
      expect(subject.environment).to be nil
      expect(subject.locale).to eq 'gb'
    end
  end
end
