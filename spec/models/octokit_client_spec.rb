require 'spec_helper'
require 'octokit_client'

RSpec.describe OctokitClient do
  describe '#repo_accessible?' do
    context 'when repo is on GitHub' do
      let(:uris) {
        %w(git@github.com:owner/repo.git
           git://github.com/owner/repo.git
           http://github.com/owner/repo
           ssh://github.com/owner/repo.git)
      }
      it 'checks that the repo is accessible' do
        uris.each do |uri|
          expect_any_instance_of(Octokit::Client).to receive(:repository?).with('owner/repo')
          OctokitClient.instance.repo_accessible?(uri)
        end
      end
    end

    context 'when repo is not on GitHub' do
      let(:uri) { 'git@bitbucket.com:owner/repo.git' }
      it 'does not check GitHub and returns nil' do
        expect_any_instance_of(Octokit::Client).to_not receive(:repository?)
        expect(OctokitClient.instance.repo_accessible?(uri)).to be_nil
      end
    end
  end
end
