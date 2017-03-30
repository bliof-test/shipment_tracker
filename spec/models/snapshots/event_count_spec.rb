# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Snapshots::EventCount do
  describe '.global_event_pointer' do
    it 'is 0 by default' do
      expect(described_class.global_event_pointer).to eq(0)
    end
  end

  describe '.global_event_pointer=' do
    it 'could be changed' do
      expect(described_class.global_event_pointer = 10).to eq(10)
      expect(described_class.global_event_pointer).to eq(10)
    end
  end
end
