# frozen_string_literal: true
require 'virtus'

class Build
  include Virtus.model

  values do
    attribute :source, String
    attribute :url, String
    attribute :success, Boolean
    attribute :app_name, String
    attribute :version, String
    attribute :build_type, String
  end
end
