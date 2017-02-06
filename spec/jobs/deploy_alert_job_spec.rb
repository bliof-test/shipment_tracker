# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DeployAlertJob do
  before do
    allow(SlackClient).to receive(:send_deploy_alert)
  end

  describe '#perform' do
    let(:deploy_attrs) do
      {
        'id' => 1,
        'app_name' => 'frontend',
        'server' => 'test.com',
        'version' => 'xyz',
        'deployed_by' => 'Bob',
        'deployed_at' => Time.new(2016, 11, 20, 14, 0, 0, 0).to_s,
        'environment' => 'production',
        'region' => 'us',
      }
    end

    it 'runs DeployAlert.audit_message with correct arguments' do
      previous_deploy = Deploy.new(deploy_attrs.merge('id' => 1))
      current_deploy = Deploy.new(deploy_attrs.merge('id' => 2))

      expect(DeployAlert).to receive(:audit_message).with(current_deploy, previous_deploy)

      DeployAlertJob.perform_now(
        current_deploy: deploy_attrs.merge('id' => 2),
        previous_deploy: deploy_attrs.merge('id' => 1),
      )
    end

    it 'will send a slack notification if there is an error' do
      expect(DeployAlert).to receive(:audit_message).and_return 'There was an error.'

      expect(SlackClient).to receive(:send_deploy_alert).with(
        'There was an error.',
        'https://localhost/releases/frontend?region=uk',
        'frontend',
        'John',
      )

      DeployAlertJob.perform_now(
        current_deploy: deploy_attrs.merge(
          'app_name' => 'frontend',
          'deployed_by' => 'John',
          'region' => 'uk',
        ),
      )
    end

    it 'will notificaty the repo owners by email if there is an error' do
      expect(DeployAlert).to receive(:audit_message).and_return 'There was an error.'

      allow_any_instance_of(Repositories::RepoOwnershipRepository).to(
        receive(:owners_of).with('frontend').and_return(
          [
            build(:repo_owner, name: 'John', email: 'john@test.com'),
            build(:repo_owner, name: 'Ivan', email: 'ivan@test.com'),
          ],
        ),
      )

      create(:git_repository_location, name: 'frontend')

      expect do
        DeployAlertJob.perform_now(
          current_deploy: deploy_attrs.merge(
            'app_name' => 'frontend',
            'deployed_by' => 'John',
            'region' => 'uk',
          ),
        )
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
