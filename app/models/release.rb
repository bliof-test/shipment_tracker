# frozen_string_literal: true

require 'virtus'

class Release
  include Virtus.value_object

  values do
    attribute :commit, GitCommit
    attribute :production_deploy_time, Time
    attribute :subject, String
    attribute :feature_reviews, Array
    attribute :deployed_by, String
  end

  def version
    commit.id
  end

  def authorised?
    feature_reviews.any?(&:authorised?)
  end
end
