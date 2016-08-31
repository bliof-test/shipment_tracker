# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Deploy do
  subject(:deploy) do
    described_class.new(
      version: 'abc',
      app_name: 'app1',
      deployed_at: time,
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
end
