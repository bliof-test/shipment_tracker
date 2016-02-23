require 'rails_helper'
require 'forms/repository_locations_form'

RSpec.describe Forms::RepositoryLocationsForm do
  subject(:form) { Forms::RepositoryLocationsForm.new(git_uri) }

  describe '#valid?' do
    describe 'URI validation', :disable_repo_verification do
      context 'when the domain is whitelisted' do
        let(:git_uri) { 'https://github.com/owner/repo.git' }
        it { is_expected.to be_valid }
      end

      context 'when the domain is not whitelisted' do
        let(:git_uri) { 'https://example.com/owner/repo.git' }
        it { is_expected.to_not be_valid }
      end

      context 'when the input is a valid Git URI' do
        it 'is valid' do
          allow_any_instance_of(URI::Generic).to receive(:host).and_return('github.com')

          aggregate_failures do
            expect(repo_form('git@github.com:owner/repo.git')).to be_valid
            expect(repo_form('ssh://git@github.com/owner/repo.git')).to be_valid
            expect(repo_form('git://git@github.com/owner/repo.git')).to be_valid
            expect(repo_form('http://github.com/owner/repo.git')).to be_valid
            expect(repo_form('https://github.com/owner/repo.git')).to be_valid
            expect(repo_form('https://github.com/owner/repo')).to be_valid
            expect(repo_form('file:///path/to/repo')).to be_valid
          end
        end
      end

      context 'when the input is not a valid Git URI' do
        it 'is not valid' do
          aggregate_failures do
            expect(repo_form('github.com\user\repo.git')).to_not be_valid
            expect(repo_form('repo')).to_not be_valid
            expect(repo_form('')).to_not be_valid
          end
        end
      end
    end

    describe 'repository accessibility' do
      context 'when the repo does not exist or we lack read permissions' do
        it 'is not valid' do
          allow_any_instance_of(Octokit::Client).to receive(:repository?).and_return(false)
          expect(repo_form('ssh://git@github.com/owner/repo.git')).to_not be_valid
        end
      end

      context 'when the check is skipped because the repo is not on GitHub' do
        it 'is not valid' do
          expect(repo_form('ssh://git@bitbucket.com/owner/repo.git')).to_not be_valid
        end
      end
    end
  end

  describe '.default_token_types' do
    let(:expected_tokens) {
      [
        { id: 'circleci', name: 'CircleCI (webhook)', value: 'true' },
        { id: 'circleci-manual', name: 'CircleCI (post test)', value: 'false' },
        { id: 'deploy', name: 'Deployment', value: 'true' },
        { id: 'jenkins', name: 'Jenkins', value: 'false' },
        { id: 'jira', name: 'JIRA', value: 'false' },
        { id: 'uat', name: 'UAT', value: 'false' },
        { id: 'github_notifications', name: 'Github Notifications', value: 'false' },
      ]
    }

    it 'returns complete list of token types and default values' do
      expect(Forms::RepositoryLocationsForm.default_token_types).to eq(expected_tokens)
    end
  end

  def repo_form(uri)
    Forms::RepositoryLocationsForm.new(uri)
  end
end
