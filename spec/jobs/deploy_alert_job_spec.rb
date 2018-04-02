# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeployAlertJob do
  before do
    allow(SlackClient).to receive(:send_deploy_alert)
  end

  describe '#perform' do
    let(:default_deploy_attrs) do
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

    def deploy_with(data = {})
      Deploy.new(deploy_attrs(data))
    end

    def deploy_attrs(data = {})
      default_deploy_attrs.merge(data)
    end

    before do
      allow(SlackClient).to receive(:send_deploy_alert)
    end

    it 'runs DeployAlert.audit_message with correct arguments' do
      previous_deploy = deploy_with('id' => 1, 'uuid' => '2d931510-d99f-494a-8c67-87feb05e1594')
      current_deploy = deploy_with('id' => 2, 'uuid' => 'bad85eb9-0713-4da7-8d36-07a8e4b00eab')

      expect(DeployAlert).to receive(:audit_message).with(current_deploy, previous_deploy)

      described_class.perform_now(
        current_deploy: deploy_attrs('id' => 2, 'uuid' => 'bad85eb9-0713-4da7-8d36-07a8e4b00eab'),
        previous_deploy: deploy_attrs('id' => 1, 'uuid' => '2d931510-d99f-494a-8c67-87feb05e1594'),
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

      described_class.perform_now(
        current_deploy: deploy_attrs(
          'app_name' => 'frontend',
          'deployed_by' => 'John',
          'region' => 'uk',
        ),
      )
    end

    it 'will notify the repo owners by email if there is an error' do
      expect(DeployAlert).to receive(:audit_message).and_return 'There was an error.'

      allow_any_instance_of(Repositories::RepoOwnershipRepository).to(
        receive(:owners_of).with('frontend').and_return(
          [
            build(:repo_admin, name: 'John', email: 'john@test.com'),
            build(:repo_admin, name: 'Ivan', email: 'ivan@test.com'),
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

    it 'creates a deploy alert event if there is an alert message' do
      current_deploy = deploy_with('id' => 2, 'uuid' => '2d931510-d99f-494a-8c67-87feb05e1594')

      expect(DeployAlert).to(
        receive(:audit_message).with(current_deploy, nil).and_return('There is a problem!'),
      )

      described_class.perform_now(
        current_deploy: deploy_attrs('id' => 2, 'uuid' => '2d931510-d99f-494a-8c67-87feb05e1594'),
        previous_deploy: nil,
      )

      deploy_alert = Events::DeployAlertEvent.last

      expect(deploy_alert.deploy_uuid).to eq('2d931510-d99f-494a-8c67-87feb05e1594')
      expect(deploy_alert.message).to eq('There is a problem!')
    end

    it "will not create a deploy alert event if there isn't an alert message" do
      current_deploy = deploy_with('id' => 2, 'uuid' => '2d931510-d99f-494a-8c67-87feb05e1594')

      expect(DeployAlert).to receive(:audit_message).with(current_deploy, nil).and_return(nil)

      described_class.perform_now(
        current_deploy: deploy_attrs('id' => 2, 'uuid' => '2d931510-d99f-494a-8c67-87feb05e1594'),
        previous_deploy: nil,
      )

      expect(Events::DeployAlertEvent.last).to be_nil
    end

    it "will not create a deploy alert event if there isn't a uuid for the deploy" do
      current_deploy = deploy_with('id' => 2)

      expect(DeployAlert).to receive(:audit_message).with(current_deploy, nil).and_return('problem')

      described_class.perform_now(
        current_deploy: deploy_attrs('id' => 2),
        previous_deploy: nil,
      )

      expect(Events::DeployAlertEvent.last).to be_nil
    end
  end
end
