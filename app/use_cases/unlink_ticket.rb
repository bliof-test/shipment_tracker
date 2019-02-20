# frozen_string_literal: true

require 'clients/jira'

class UnlinkTicket
  COMMENT_LABEL = 'Feature review was unlinked'

  include SolidUseCase
  include TicketValidationHelper

  steps :validate_id_format,
    :assert_linked,
    :post_unlink_comment

  class << self
    def build_comment(feature_review_url)
      "[#{COMMENT_LABEL}|#{feature_review_url}]"
    end
  end

  def assert_linked(args)
    tickets = Repositories::TicketRepository.new.tickets_for_path(args[:feature_review_path])

    has_links = tickets.any? { |ticket| ticket.key == args[:jira_key] }
    return fail :missing_key, message: missing_key_message(args) unless has_links

    continue(args)
  end

  def post_unlink_comment(args)
    comment = self.class.build_comment("#{args[:root_url].chomp('/')}#{args[:feature_review_path]}")
    JiraClient.post_comment(args[:jira_key], comment)
    continue(success_message(args))
  rescue JiraClient::InvalidKeyError
    fail :invalid_key, message: invalid_key_message(args)
  rescue StandardError => error
    Honeybadger.notify(error)
    fail :post_failed, message: generic_error_message(args)
  end

  private

  def invalid_key_message(args)
    "Failed to unlink #{args[:jira_key]}. Please check that the ticket ID is correct."
  end

  def missing_key_message(args)
    "Failed to unlink #{args[:jira_key]}. Existing link couldn't be found."
  end

  def generic_error_message(args)
    "Failed to unlink #{args[:jira_key]}. Something went wrong."
  end

  def success_message(args)
    "Feature Review was unlinked from #{args[:jira_key]}. Refresh this page in a moment and the ticket will disappear."
  end
end
