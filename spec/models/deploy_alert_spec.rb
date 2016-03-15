# frozen_string_literal: true
require 'rails_helper'
require 'deploy_alert'
require 'deploy'
require 'git_repository'
require 'support/repository_builder'

RSpec.describe DeployAlert do
  describe '.auditable?' do
    before do
      allow(GitRepositoryLocation).to receive(:app_names).and_return(['some_app'])
    end

    context 'when environment is not production' do
      let(:deploy) { Deploy.new(environment: 'staging') }

      it 'returns false' do
        expect(DeployAlert.auditable?(deploy)).to be false
      end
    end

    context 'when app not under audit' do
      let(:deploy) { Deploy.new(app_name: 'another_app', environment: 'production') }

      it 'returns false' do
        expect(DeployAlert.auditable?(deploy)).to be false
      end
    end

    context 'when environment is production and app is under audit' do
      let(:deploy) { Deploy.new(app_name: 'some_app', environment: 'production') }

      it 'returns true' do
        expect(DeployAlert.auditable?(deploy)).to be true
      end
    end
  end

  describe '#audit_message' do
    let(:release) { instance_double(Release, authorised?: true) }
    let(:projection) { instance_double(Queries::ReleasesQuery, deployed_releases: [release]) }

    before do
      allow(Queries::ReleasesQuery).to receive(:new).and_return(projection)
      allow(GitRepositoryLoader).to receive_message_chain(:from_rails_config, :load).and_return(git_repo)
    end

    let(:git_repo) {
      instance_double(
        GitRepository,
        commit_on_master?: true,
        ancestor_of?: false,
        commits_between: [],
        commit_for_version: [],
      )
    }

    let(:current_deploy) {
      instance_double(
        Deploy,
        app_name: 'some_app',
        version: '#new',
        region: 'gb',
        event_created_at: Time.current,
        deployed_by: 'Devloper',
      )
    }

    let(:previous_deploy) {
      instance_double(
        Deploy,
        app_name: 'some_app',
        version: '#old',
        region: 'gb',
        event_created_at: 1.hour.ago,
        deployed_by: 'Devloper',
      )
    }

    describe 'Alert: not on master' do
      context 'when deployed commit exists on master' do
        it 'returns nil' do
          allow(git_repo).to receive(:commit_on_master?).with(current_deploy.version).and_return(true)

          expect(DeployAlert.audit_message(current_deploy)).to be nil
        end
      end

      context 'when deployed commit does not exist on master' do
        it 'returns an alert message for commit not on master' do
          allow(git_repo).to receive(:commit_on_master?).with(current_deploy.version).and_return(false)

          actual = DeployAlert.audit_message(current_deploy)
          expected = message(current_deploy, 'Version does not exist on GitHub master branch.')

          expect(actual).to eq(expected)
        end
      end
    end

    describe 'Alert: unknown version' do
      context 'when deploy event does not have version' do
        let(:deploy) {
          instance_double(
            Deploy,
            app_name: 'some_app',
            version: nil,
            region: 'gb',
            deployed_by: 'Devloper',
            event_created_at: Time.current,
          )
        }

        it 'returns an alert message for missing software version' do
          actual = DeployAlert.audit_message(deploy)
          expected = message(deploy, 'Deploy event sent to Shipment Tracker is missing the software version.')

          expect(actual).to eq(expected)
        end
      end
    end

    describe 'Alert: unauthorised release' do
      context 'when it is the first production deploy' do
        context 'when release is not authorized' do
          let(:release) { instance_double(Release, authorised?: false) }

          it 'returns an alert message for unauthorised release' do
            actual = DeployAlert.audit_message(current_deploy)
            expected = message(current_deploy, 'Release not authorised; Feature Review not approved.')

            expect(actual).to eq(expected)
          end
        end

        context 'when release is authorized' do
          let(:release) { instance_double(Release, authorised?: true) }

          it 'returns nil' do
            expect(DeployAlert.audit_message(current_deploy)).to be nil
          end
        end
      end

      context 'when there are previous deploys to production' do
        context 'when release is not authorized' do
          let(:release) { instance_double(Release, authorised?: false) }

          it 'returns an alert message for unauthorised release' do
            actual = DeployAlert.audit_message(current_deploy, previous_deploy)
            expected = message(current_deploy, 'Release not authorised; Feature Review not approved.')

            expect(actual).to eq(expected)
          end
        end

        context 'when release is authorized' do
          let(:release) { instance_double(Release, authorised?: true) }

          it 'returns nil' do
            expect(DeployAlert.audit_message(current_deploy, previous_deploy)).to be nil
          end
        end
      end
    end

    describe 'Alert: rollback' do
      context 'when an old release is deployed' do
        it 'returns an alert message for rollback' do
          allow(git_repo).to receive(:ancestor_of?).with(current_deploy.version, previous_deploy.version)
            .and_return(true)

          actual = DeployAlert.audit_message(current_deploy, previous_deploy)
          expected = message(current_deploy, 'Old release deployed. Was the rollback intentional?')

          expect(actual).to eq(expected)
        end
      end

      context 'when a new release is deployed' do
        it 'does not alert' do
          allow(git_repo).to receive(:ancestor_of?).with(current_deploy.version, previous_deploy.version)
            .and_return(false)

          expect(DeployAlert.audit_message(current_deploy, previous_deploy)).to be nil
        end
      end

      context 'when the first ever release is deployed' do
        it 'does not alert' do
          expect(DeployAlert.audit_message(current_deploy)).to be nil
        end
      end
    end
  end

  private

  def message(deploy, reason)
    "#{deploy.region.upcase} Deploy Alert for #{deploy.app_name} " \
    "at #{deploy.event_created_at.strftime('%F %H:%M%:z')}.\n"\
    "#{deploy.deployed_by} deployed #{deploy.version || 'unknown version'}. " << reason
  end

  def version(pretend_version)
    test_git_repo.commit_for_pretend_version(pretend_version)
  end
end
