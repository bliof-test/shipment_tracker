# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Events::RepoOwnershipEvent do
  describe 'init' do
    it 'works' do
      event = described_class.new(
        details: {
          'app_name' => 'Some_App',
          'repo_owners' => 'Test <test@example.com>, test2@example.com',
          'repo_approvers' => 'Approver <approver@example.com>, approver2@example.com',
        },
      )

      expect(event.app_name).to eq('Some_App')
      expect(event.repo_owners).to eq('Test <test@example.com>, test2@example.com')
      expect(event.repo_approvers).to eq('Approver <approver@example.com>, approver2@example.com')
    end
  end
end
