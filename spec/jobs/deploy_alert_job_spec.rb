require 'rails_helper'

RSpec.describe DeployAlertJob do
  describe '#perform' do
    let(:deploy_attrs) {
      {
        'id' => 1,
        'app_name' => 'frontend',
        'server' => 'test.com',
        'version' => 'xyz',
        'deployed_by' => 'Bob',
        'event_created_at' => Time.now.to_s,
        'environment' => 'production',
        'region' => 'us',
      }
    }
    let(:expected_arg) {
      Deploy.new(deploy_attrs)
    }

    it 'runs DeployAlertJob.audit with correct arguments' do
      allow(DeployAlert).to receive(:audit)
      expect(DeployAlert).to receive(:audit).with(expected_arg)

      DeployAlertJob.perform_now(deploy_attrs)
    end
  end
end
