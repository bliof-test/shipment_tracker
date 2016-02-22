require 'spec_helper'
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
    end
  end

  def repo_form(uri)
    Forms::RepositoryLocationsForm.new(uri)
  end
end
