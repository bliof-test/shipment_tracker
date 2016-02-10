class Deploy
  include Virtus.value_object

  values do
    attribute :app_name, String
    attribute :correct, Boolean
    attribute :deployed_by, String
    attribute :event_created_at, DateTime
    attribute :server, String
    attribute :region, String
    attribute :version, String
  end
end
