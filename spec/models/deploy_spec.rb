# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Deploy do
  subject(:deploy) do
    described_class.new(
      version: 'abc',
      app_name: 'app1',
      event_created_at: time,
      deployed_by: 'user',
    )
  end

  let(:commit) { GitCommit.new(id: 'abc') }
  let(:time) { Time.current }

  describe '#deployed_at' do
    it 'returns the event creation time' do
      expect(deploy.deployed_at).to eq(time)
    end
  end

  describe '#commit' do
    let(:repository_loader) { instance_double(GitRepositoryLoader) }
    let(:repository) { instance_double(GitRepository) }

    before do
      allow(GitRepositoryLoader).to receive(:from_rails_config).and_return(repository_loader)
      allow(repository_loader).to receive(:load).and_return(repository)

      allow(repository).to receive(:commit_for_version).with(commit.id).and_return(commit)
    end

    it 'returns the commit object' do
      expect(subject.commit).to eq(commit)
    end
  end

  describe '#similar_to?' do
    context 'when a deploy with the same app name and version is passed in' do
      let(:another_deploy) do
        Deploy.new(
          version: 'abc',
          app_name: 'app1',
          event_created_at: time + 1.hour,
          deployed_by: 'user',
        )
      end

      it 'returns true' do
        expect(subject.similar_to?(another_deploy)).to eq(true)
      end
    end

    context 'when a deploy with different app name or version is passed in' do
      let(:deploy_with_different_version) do
        Deploy.new(
          version: 'def',
          app_name: 'app1',
          event_created_at: time + 1.hour,
          deployed_by: 'user',
        )
      end
      let(:deploy_with_different_app_name) do
        Deploy.new(
          version: 'abc',
          app_name: 'app2',
          event_created_at: time + 2.hours,
          deployed_by: 'user',
        )
      end

      it 'returns false' do
        expect(subject.similar_to?(deploy_with_different_version)).to eq(false)
        expect(subject.similar_to?(deploy_with_different_app_name)).to eq(false)
      end
    end
  end
end
