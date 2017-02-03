# frozen_string_literal: true
module Factories
  class EventFactory
    def initialize(event_type_repository)
      @event_type_repository = event_type_repository
    end

    def self.from_rails_config
      new(EventTypeRepository.from_rails_config)
    end

    def build(endpoint:, payload:, user: nil)
      type = event_type_repository.find_by_endpoint(endpoint)

      data = format_payload(payload, type, user)

      type.event_class.new(data)
    end

    private

    attr_reader :event_type_repository

    def format_payload(payload, type, user)
      metadata = {}

      if type.internal? && user && user.email.present?
        metadata = { 'email' => user.email }
      end

      { details: payload.merge(metadata) }
    end
  end
end
