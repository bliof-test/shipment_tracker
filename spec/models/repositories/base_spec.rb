# frozen_string_literal: true

require 'rails_helper'
require 'repositories/base'

module Spec
  class TestRepositoriesBase < Repositories::Base
    def initialize(store)
      @store = store
    end

    def apply; end
  end
end

RSpec.describe 'Repositories::Base' do
  def repository_for(store)
    Spec::TestRepositoriesBase.new(store)
  end

  describe '#indentifier' do
    it 'is the table name of the store' do
      expect(repository_for(double('store', table_name: 'test-store')).identifier).to eq('test-store')
    end
  end

  describe '#last_applied_event_id' do
    it 'returns the last event applied by the repo' do
      repository = repository_for(double('store', table_name: 'test-store'))

      expect(Snapshots::EventCount).to receive(:pointer_for).with('test-store')

      repository.last_applied_event_id
    end
  end
end
