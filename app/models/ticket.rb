require 'virtus'

class Ticket
  include Virtus.value_object

  values do
    attribute :key, String
    attribute :summary, String, default: ''
    attribute :status, String, default: 'To Do'
    attribute :paths, Array, default: []
    attribute :approved_at, DateTime
    attribute :event_created_at, DateTime
    attribute :versions, Array, default: []
  end

  def approved?
    Rails.application.config.approved_statuses.include?(status)
  end

  def authorised?
    return false if approved_at.nil?
    approved_at < event_created_at
  end
end
