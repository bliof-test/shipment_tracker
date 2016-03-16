require 'virtus'

class Build
  include Virtus.value_object

  values do
    attribute :source, String
    attribute :success, Boolean
    attribute :version, String
  end
end
