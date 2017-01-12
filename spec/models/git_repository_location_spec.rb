# frozen_string_literal: true
require 'rails_helper'

RSpec.describe GitRepositoryLocation, :disable_repo_verification do
  describe 'before validations' do
    it 'extracts the name from the URI' do
      location = GitRepositoryLocation.create(uri: 'git@github.com/owner/repo.git')
      expect(location.name).to eq('repo')
    end

    it 'strips whitespace from the URI' do
      location = GitRepositoryLocation.create(uri: '  git@github.com/owner/repo.git  ')
      expect(location.uri).to eq('git@github.com/owner/repo.git')
    end
  end

  describe 'validations' do
    it 'must have a unique name' do
      GitRepositoryLocation.create(uri: 'https://github.com/FundingCircle/shipment_tracker.git')
      duplicate_name = GitRepositoryLocation.new(uri: 'https://github.com/OtherOrg/shipment_tracker.git')
      expect(duplicate_name).not_to be_valid
      expect(duplicate_name.errors[:name]).to contain_exactly('has already been taken')
    end
  end

  describe '.uris' do
    it 'returns an array of URIs' do
      uris = %w(ssh://git@github.com/owner/foo.git git@github.com:owner/bar.git)
      uris.each do |uri|
        GitRepositoryLocation.create(uri: uri)
      end

      expect(GitRepositoryLocation.uris).to match_array(uris)
    end
  end

  describe '.app_remote_head_hash' do
    before do
      GitRepositoryLocation.create(name: 'app1', remote_head: 'abc123', uri: '/app1')
      GitRepositoryLocation.create(name: 'app2', remote_head: 'abc456', uri: '/app2')
    end

    it 'returns a hash of app names and remote head locations' do
      expect(GitRepositoryLocation.app_remote_head_hash).to eql('app1' => 'abc123', 'app2' => 'abc456')
    end
  end

  describe '.github_url_for_app' do
    let(:app_name) { 'repo' }
    let(:url) { 'https://github.com/organization/repo' }

    context 'when a repository location exists with the app name' do
      before do
        GitRepositoryLocation.create(uri: uri)
      end

      [
        'ssh://git@github.com/organization/repo.git',
        'git://git@github.com/organization/repo.git',
        'https://github.com/organization/repo.git',
        'git@github.com:organization/repo.git',
      ].each do |uri|
        context "when the uri is #{uri}" do
          let(:uri) { uri }

          it 'returns a URL to the GitHub repository' do
            github_repo_url = GitRepositoryLocation.github_url_for_app(app_name)
            expect(github_repo_url).to eq(url)
          end
        end
      end
    end

    context 'when no repository locations exists with the app name' do
      it 'returns nil' do
        expect(GitRepositoryLocation.github_url_for_app(app_name)).to be nil
      end
    end
  end

  describe '.github_urls_for_apps' do
    context 'when given a list of app names' do
      before do
        GitRepositoryLocation.create(name: 'app1', uri: 'https://github.com/owner/app1')
        GitRepositoryLocation.create(name: 'app2', uri: 'git@github.com:owner/app2.git')
      end

      it 'returns a hash of app names and urls' do
        result = GitRepositoryLocation.github_urls_for_apps(%w(app1 app2 app3))
        expect(result).to eq(
          'app1' => 'https://github.com/owner/app1',
          'app2' => 'https://github.com/owner/app2',
          'app3' => nil,
        )
      end
    end

    context 'when not given any app names' do
      it 'returns an empty hash' do
        expect(GitRepositoryLocation.github_urls_for_apps([])).to eq({})
      end
    end
  end

  describe '.find_by_full_repo_name' do
    context 'when a GitRepositoryLocation exists with the same name' do
      it 'returns a GitRepositoryLocation' do
        GitRepositoryLocation.create(uri: 'git@github.com:owner/repo-frontend.git')
        GitRepositoryLocation.create(uri: 'git@github.com:owner/old-repo-frontend.git')
        repo_location = GitRepositoryLocation.create(uri: 'git@github.com:owner/repo.git')

        result = GitRepositoryLocation.find_by_full_repo_name('owner/repo')
        expect(result).to eq(repo_location)
      end
    end

    context 'when a GitRepositoryLocation does not exist with the same name' do
      it 'returns nil' do
        result = GitRepositoryLocation.find_by_full_repo_name('owner/repo')
        expect(result).to be_nil
      end
    end
  end

  describe '.repo_tracked?' do
    context 'when the repository is tracked' do
      it 'returns true' do
        GitRepositoryLocation.create(uri: 'git@github.com:owner/repo.git')

        expect(GitRepositoryLocation.repo_tracked?('owner/repo')).to be true
      end
    end

    context 'when the repistory is not tracked' do
      it 'returns false' do
        GitRepositoryLocation.create(uri: 'git@github.com:owner/another-repo.git')

        expect(GitRepositoryLocation.repo_tracked?('owner/repo')).to be false
      end
    end
  end

  describe '#full_repo_name' do
    it 'returns the full repository name' do
      repository_loction = GitRepositoryLocation.create(uri: 'git@github.com:owner/repo.git')

      expect(repository_loction.full_repo_name).to eq('owner/repo')
    end
  end
end
