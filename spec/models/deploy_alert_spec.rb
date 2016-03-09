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

    context 'deployed commit on master' do
      let(:test_git_repo) { Support::RepositoryBuilder.build(git_diagram) }
      let(:rugged_repo) { Rugged::Repository.new(test_git_repo.dir) }
      let(:repo) { GitRepository.new(rugged_repo) }
      let(:git_diagram) { '-o-A-o' }

      let(:sha) { version('A') }
      let(:deploy) {
        Deploy.new(
          version: sha, environment: 'production', app_name: app_name,
          deployed_by: 'user1', event_created_at: DateTime.parse('2016-02-15T15:57:25+01:00'))
      }

      before do
        allow(GitRepositoryLoader).to receive(:from_rails_config).and_return(repository_loader)
        allow(repository_loader).to receive(:load).with(app_name).and_return(repo)
        allow(GitRepositoryLocation).to receive(:app_names).and_return([app_name])
      end

      it 'returns nil' do
        expect(DeployAlert.audit(deploy)).to eq(nil)
      end
    end

    context 'deployed commit not on master' do
      let(:test_git_repo) { Support::RepositoryBuilder.build(git_diagram) }
      let(:rugged_repo) { Rugged::Repository.new(test_git_repo.dir) }
      let(:repo) { GitRepository.new(rugged_repo) }
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
          deployed_by: 'user1', event_created_at: DateTime.parse('2016-02-15T15:57:25+01:00'),
          region: 'uk')
      }

      let(:expected_message) {
        'UK Deploy Alert for frontend at 2016-02-15 15:57+01:00. ' \
        "user1 deployed #{sha} not on master branch."
      }

      before do
        allow(GitRepositoryLoader).to receive(:from_rails_config).and_return(repository_loader)
        allow(repository_loader).to receive(:load).with(app_name).and_return(repo)
        allow(GitRepositoryLocation).to receive(:app_names).and_return([app_name])
      end

      it 'returns a message' do
        expect(DeployAlert.audit(deploy)).to eq(expected_message)
      end
    end

    context 'deploy event does not have version' do
      let(:test_git_repo) { Support::RepositoryBuilder.build(git_diagram) }
      let(:rugged_repo) { Rugged::Repository.new(test_git_repo.dir) }
      let(:repo) { GitRepository.new(rugged_repo) }
      let(:deploy) {
        Deploy.new(
          version: nil, environment: 'production', app_name: app_name,
          deployed_by: 'user1', event_created_at: DateTime.parse('2016-02-15T15:57:25+01:00'),
          region: 'us')
      }
      let(:git_diagram) { '-A' }

      let(:expected_message) {
        'US Deploy Alert for frontend at 2016-02-15 15:57+01:00. ' \
        'user1 deployed unknown not on master branch.'
      }

      before do
        allow(GitRepositoryLoader).to receive(:from_rails_config).and_return(repository_loader)
        allow(repository_loader).to receive(:load).with(app_name).and_return(repo)
        allow(GitRepositoryLocation).to receive(:app_names).and_return([app_name])
      end

      it 'returns a message' do
        expect(DeployAlert.audit(deploy)).to eq(expected_message)
      end
    end

    context 'deploy is unauthorised' do
      let(:time) { Time.current.change(usec: 0) }
      let(:new_deploy) {
        instance_double(
          Deploy, app_name: 'fca',
                  version: '#abc', region: 'foo',
                  event_created_at: time,
                  deployed_by: 'shrek'
        )
      }
      let(:git_commits) { [] }
      let(:projection) { instance_double(Queries::ReleasesQuery, deployed_releases: [release]) }
      let(:git_repository) { instance_double(GitRepository, commit_for_version: git_commits, commit_on_master?: true) }
      let(:release) { instance_double(Release, authorised?: false) }

      let(:expected_message) {
        "FOO Deploy Alert for fca at #{time.strftime('%F %H:%M%:z')}. "\
        'shrek deployed #abc, release not authorised.'
      }

      before do
        allow(Queries::ReleasesQuery).to receive(:new).and_return(projection)
        allow(GitRepositoryLoader).to receive_message_chain(:from_rails_config, :load).and_return(git_repository)
      end

      it 'sends an alert' do
        expect(DeployAlert.audit(new_deploy)).to eq(expected_message)
      end
    end
  end

  private

  def version(pretend_version)
    test_git_repo.commit_for_pretend_version(pretend_version)
  end
end
