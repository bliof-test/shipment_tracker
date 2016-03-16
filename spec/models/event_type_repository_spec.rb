require 'rails_helper'

RSpec.describe EventTypeRepository do
  subject(:repository) {
    EventTypeRepository.new(
      [
        EventType.new(name: 'Foo', endpoint: 'foo'),
        EventType.new(name: 'Bar', endpoint: 'bar', internal: true),
      ],
    )
  }

  describe '#find_by_endpoint' do
    it 'returns the event type corresponding to a given endpoint' do
      expect(repository.find_by_endpoint('foo').name).to eq('Foo')
    end

    context 'with an unrecognized event type' do
      it 'raises an error' do
        expect {
          repository.find_by_endpoint('unexistent')
        }.to raise_error("Unrecognized event type 'unexistent'")
      end
    end
  end

  describe '#external_types' do
    it 'returns a list of all external event types' do
      external_types = repository.external_types.map(&:name)

      expect(external_types).to include('Foo')
      expect(external_types).to_not include('Bar')
    end
  end
end
