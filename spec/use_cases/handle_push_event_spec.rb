require 'rails_helper'
require 'handle_push_event'

RSpec.describe HandlePushEvent do
  describe 'updating remote head' do
    it 'updates the corresponding repository location' do
      github_payload = instance_double(Payloads::Github, full_repo_name: 'owner/repo', after_sha: 'abc123')

      git_repository_location = instance_double(GitRepositoryLocation)
      allow(GitRepositoryLocation).to receive(:find_by_full_repo_name).and_return(git_repository_location)

      expect(git_repository_location).to receive(:update).with(remote_head: 'abc123')
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
  end
end
