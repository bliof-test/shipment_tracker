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
    attribute :authored_by, String
    attribute :approved_at, DateTime
    attribute :approved_by, String
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

  def authorised?(versions_under_review, isae_3402_auditable = false)
    return false if approved_at.nil? || (isae_3402_auditable && authorised_by_developer?)
    linked_at = versions_under_review.map { |v| version_timestamps[v] }.compact.min
    return false if linked_at.nil?
    approved_at >= linked_at
  end

  def authorised_by_developer?
    authored_by.present? && approved_by.present? && authored_by == approved_by
  end
end
