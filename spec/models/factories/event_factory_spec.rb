# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Factories::EventFactory do
  def factory_for(event_types = nil)
    repository = instance_double(EventTypeRepository)

    event_types.each do |event_type|
      allow(repository).to receive(:find_by_endpoint).with(event_type.endpoint).and_return(event_type)
    end

    described_class.new(repository)
  end

  class ExternalEvent < Events::BaseEvent
  end

  class InternalEvent < Events::BaseEvent
  end

  subject(:factory) do
    event_types ||= [
      EventType.new(endpoint: 'internal', event_class: InternalEvent, internal: true),
      EventType.new(endpoint: 'external', event_class: ExternalEvent, internal: false),
    ]

    factory_for(event_types)
  end

  describe '#build' do
    it 'builds an event for a specific endpoint' do
      internal_event = factory.build(endpoint: 'internal', payload: { 'foo' => 'bar' })
      expect(internal_event).to be_kind_of(InternalEvent)
      expect(internal_event.details).to eq('foo' => 'bar')

      external_event = factory.build(endpoint: 'external', payload: { 'foo2' => 'bar2' })
      expect(external_event).to be_kind_of(ExternalEvent)
      expect(external_event.details).to eq('foo2' => 'bar2')
    end

    context 'when handling internal events' do
      it 'will include the current user email in the event details' do
        event = factory.build(
          endpoint: 'internal',
          payload: { 'foo' => 'bar' },
          user: User.new(email: 'test@example.com'),
        )

        expect(event.details).to eq('foo' => 'bar', 'email' => 'test@example.com')
      end
    end

    context 'when handling external events' do
      it 'will not try to set the email for the current user' do
        event = factory.build(
          endpoint: 'external',
          payload: { 'foo' => 'bar' },
          user: User.new(email: 'test@example.com'),
        )

        expect(event.details).to eq('foo' => 'bar')
      end
    end

    it "will raise an exception when there isn't a suitable event type for the endpoint" do
      expect do
        described_class.new(EventTypeRepository.new).build(endpoint: 'test', payload: {})
      end.to raise_error(StandardError)
    end
  end
end
