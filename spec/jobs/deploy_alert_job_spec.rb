require 'rails_helper'

RSpec.describe DeployAlertJob do
  describe '#perform' do
    let(:time) { Time.current.change(usec: 0) }

    let(:deploy_attrs) {
      {
        new_deploy: {
          'id' => 1,
          'app_name' => 'frontend',
          'server' => 'test.com',
          'version' => 'xyz',
          'deployed_by' => 'Bob',
          'event_created_at' => time.to_s,
          'environment' => 'production',
          'region' => 'us',
        },
      }
    }

    let(:expected_deploy) {
      Deploy.new(deploy_attrs[:new_deploy].merge(event_created_at: time))
    }

    it 'runs DeployAlertJob.audit with correct arguments' do
      expect(DeployAlert).to receive(:audit).with(expected_deploy, nil)

      DeployAlertJob.perform_now(deploy_attrs)
    end
  end
end
