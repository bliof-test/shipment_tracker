# frozen_string_literal: true
class Merge
  include Virtus.model

  attribute :app_name, String
  attribute :sha, String
  attribute :merged_by, String
  attribute :merged_at, Time
  attribute :deploys, Array
end
