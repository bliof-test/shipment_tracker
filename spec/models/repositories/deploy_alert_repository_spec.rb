# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Repositories::DeployAlertRepository do
  describe '#apply' do
    it 'will store the deploy alert for the deploy with the specific uuid' do
      event = build(
        :deploy_alert_event,
        uuid: 'bad85eb9-0713-4da7-8d36-07a8e4b00eab',
        message: 'A deploy alert!!',
      )

      snapshot = create(
        :deploy_snapshot,
        uuid: 'bad85eb9-0713-4da7-8d36-07a8e4b00eab',
        deploy_alert: nil,
      )

      expect { described_class.new.apply(event) }.to(
        change { snapshot.reload.deploy_alert }.to('A deploy alert!!'),
      )
    end
  end
end
