# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Events::GitRepositoryLocationEvent do
  describe 'init' do
    it 'is initialized as expected' do
      event = described_class.new(
        details: {
          'app_name' => 'Some_App',
          'required_checks' => [],
        },
      )

      expect(event.app_name).to eq('Some_App')
      expect(event.required_checks).to eq([])
    end
  end
end
