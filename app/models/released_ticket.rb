require 'virtus'

class ReleasedTicket
  include Virtus.value_object

  values do
    attribute :key, String
    attribute :summary, String, default: ''
    attribute :description, String, default: ''
    attribute :versions, Array, default: []
    attribute :deploys, Array, default: []
  end
end
