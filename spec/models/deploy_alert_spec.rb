require 'rails_helper'
require 'deploy_alert'
require 'deploy'
require 'git_repository'
require 'support/repository_builder'

RSpec.describe DeployAlert do
  let(:app_name) { 'frontend' }

  describe '.auditable?' do
    before do
      allow(GitRepositoryLocation).to receive(:app_names).and_return([app_name])
    end

    context 'non-production env' do
      let(:deploy) { Deploy.new(environment: 'staging') }

      it 'returns false' do
        expect(DeployAlert.auditable?(deploy)).to be false
      end
    end

    context 'app not under audit' do
      let(:deploy) { Deploy.new(app_name: 'something', environment: 'production') }

      it 'returns false' do
        expect(DeployAlert.auditable?(deploy)).to be false
      end
    end

    context 'production env and app is under audit' do
      let(:deploy) { Deploy.new(app_name: app_name, environment: 'production') }

      it 'returns true' do
        expect(DeployAlert.auditable?(deploy)).to be true
      end
    end
  end

  describe '#audit' do
    let(:repository_loader) { instance_double(GitRepositoryLoader) }
    let(:test_git_repo) { Support::RepositoryBuilder.build(git_diagram) }
    let(:rugged_repo) { Rugged::Repository.new(test_git_repo.dir) }
    let(:repo) { GitRepository.new(rugged_repo) }

    before do
      allow(GitRepositoryLoader).to receive(:from_rails_config).and_return(repository_loader)
      allow(repository_loader).to receive(:load).with(app_name).and_return(repo)
      allow(GitRepositoryLocation).to receive(:app_names).and_return([app_name])
    end

    context 'deployed commit on master' do
      let(:git_diagram) { '-o-A-o' }

      let(:sha) { version('A') }
      let(:deploy) {
        Deploy.new(
          version: sha, environment: 'production', app_name: app_name,
          deployed_by: 'user1', event_created_at: DateTime.parse('2016-02-15T15:57:25+01:00'))
      }

      it 'returns nil' do
        expect(DeployAlert.audit(deploy)).to eq(nil)
      end
    end

    context 'deployed commit not on master' do
      let(:git_diagram) do
        <<-'EOS'
             o-A-o
            /
          -o-----o
        EOS
      end

      let(:sha) { version('A') }
      let(:deploy) {
        Deploy.new(
          version: sha, environment: 'production', app_name: app_name,
          deployed_by: 'user1', event_created_at: DateTime.parse('2016-02-15T15:57:25+01:00'))
      }

      let(:expected_message) {
        'Deploy Alert for frontend at 2016-02-15 15:57+01:00. ' \
        "user1 deployed version #{sha} not on master branch."
      }

      it 'returns a message' do
        expect(DeployAlert.audit(deploy)).to eq(expected_message)
      end
    end
  end

  private

  def version(pretend_version)
    test_git_repo.commit_for_pretend_version(pretend_version)
  end
end
