require 'rails_helper'

RSpec.describe Factories::EventFactory do
  let(:repository) { instance_double(EventTypeRepository) }
  subject(:factory) { described_class.new(repository) }

  describe '#create' do
    let(:payload) { { 'foo' => 'bar' } }
    let(:user_email) { 'foo@bar.com' }
    let(:event_type) {
      EventType.new(endpoint: 'circleci', event_class: Events::CircleCiEvent)
    }

    before do
      allow(repository).to receive(:find_by_endpoint).with(event_type.endpoint).and_return(event_type)
    end

    let(:created_event) { subject.create(event_type.endpoint, payload, user_email) }

    it 'returns an instance of the correct class' do
      expect(created_event).to be_an_instance_of(Events::CircleCiEvent)
    end

    it 'stores the payload in the event details' do
      expect(created_event.details).to eq('foo' => 'bar')
    end

    context 'with an internal event type' do
      let(:event_type) {
        EventType.new(endpoint: 'manual_test', event_class: Events::ManualTestEvent, internal: true)
      }

      it 'stores the payload in the event details, including the user email' do
        expect(created_event.details).to eq('foo' => 'bar', 'email' => 'foo@bar.com')
      end

      context 'when the user email is nil' do
        let(:user_email) { nil }

        it 'omits the email from the payload' do
          expect(created_event.details).to eq('foo' => 'bar')
        end
      end
    end
  end
end
