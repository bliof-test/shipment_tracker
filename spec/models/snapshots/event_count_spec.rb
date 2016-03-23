# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Snapshots::EventCount do
  describe '.repo_event_id_hash' do
    before do
      Snapshots::EventCount.create([
        { snapshot_name: 'foo', event_id: 1 },
        { snapshot_name: 'bar', event_id: 2 },
      ])
    end

    it 'returns a hash with all snapshot names and event ids' do
      result = Snapshots::EventCount.repo_event_id_hash
      expect(result).to eq('foo' => 1, 'bar' => 2)
    end
  end
end
