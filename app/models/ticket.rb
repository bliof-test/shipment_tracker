# frozen_string_literal: true
require 'virtus'

class Ticket
  include Virtus.value_object

  values do
    attribute :key, String
    attribute :summary, String, default: ''
    attribute :description, String, default: ''
    attribute :status, String, default: 'To Do'
    attribute :paths, Array, default: []
    attribute :approved_at, DateTime
    attribute :version_timestamps, Hash[String => DateTime]
    attribute :versions, Array, default: []
  end

  def authorisation_status(versions_under_review)
    return 'Requires reapproval' if approved? && !authorised?(versions_under_review)
    status
  end

  def approved?
    Rails.application.config.approved_statuses.include?(status)
  end

  def authorised?(versions_under_review)
    return false if approved_at.nil?
    linked_at = versions_under_review.map { |v| version_timestamps[v] }.compact.min
    return false if linked_at.nil?
    approved_at >= linked_at
  end
end
