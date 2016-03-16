module Factories
  class EventFactory
    def initialize(event_type_repository)
      @event_type_repository = event_type_repository
    end

    def self.from_rails_config
      new(EventTypeRepository.from_rails_config)
    end

    def create(endpoint, payload, user_email)
      type = event_type_repository.find_by_endpoint(endpoint)
      details = decorate_with_email(payload, type, user_email)
      type.event_class.create(details: details)
    end

    private

    attr_reader :event_type_repository

    def decorate_with_email(payload, type, email)
      return payload unless type.internal? && email.present?
      payload.merge('email' => email)
    end
  end
end
