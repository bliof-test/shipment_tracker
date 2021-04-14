# frozen_string_literal: true

class Token < ApplicationRecord
  has_secure_token :value

  before_validation(on: %i[create update]) do
    lowercase_name
  end

  def self.valid?(source, token)
    token.present? && exists?(source: source, value: token)
  end

  def self.revoke(id)
    find(id).destroy
  end

  def self.sources
    EventTypeRepository.from_rails_config.external_types +
      [OpenStruct.new(endpoint: 'github_notifications', name: 'Github Notifications')]
  end

  def source_name
    if source == 'github_notifications'
      'Github Notifications'
    else
      EventTypeRepository.from_rails_config.find_by_endpoint(source).name
    end
  end

  private

  def lowercase_name
    name&.downcase!
  end
end
