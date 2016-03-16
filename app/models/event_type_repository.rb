class EventTypeRepository
  def initialize(event_types)
    @event_types = event_types
  end

  def self.from_rails_config
    new(Rails.application.config.event_types)
  end

  def find_by_endpoint(endpoint)
    @event_types.find { |t| t.endpoint == endpoint }.tap do |type|
      fail "Unrecognized event type '#{endpoint}'" if type.nil?
    end
  end

  def external_types
    @event_types.select(&:external?)
  end
end
