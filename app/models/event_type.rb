class EventType
  include Virtus.value_object

  values do
    attribute :name, String
    attribute :endpoint, String
    attribute :event_class, Class
    attribute :internal, Boolean
  end

  def external?
    !internal?
  end
end
