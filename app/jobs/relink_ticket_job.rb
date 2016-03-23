# frozen_string_literal: true
require 'clients/jira'
require 'honeybadger'
require 'repositories/ticket_repository'

class RelinkTicketJob < ActiveJob::Base
  queue_as :default

  def perform(args)
    before_sha = args.delete(:before_sha)
    after_sha = args.delete(:after_sha)
    full_repo_name = args.delete(:full_repo_name)
    branch_created = args.delete(:branch_created)

    linked_tickets = relink_tickets(before_sha, after_sha) unless branch_created

    post_not_found_status(full_repo_name: full_repo_name, sha: after_sha) \
      if branch_created || linked_tickets&.empty?
    post_error_status(full_repo_name: full_repo_name, sha: after_sha) if @send_error_status
  end

  private

  def relink_tickets(before_sha, after_sha)
    ticket_repo = Repositories::TicketRepository.new
    linked_tickets = ticket_repo.tickets_for_versions(before_sha)

    linked_tickets.each do |ticket|
      ticket.paths.each do |feature_review_path|
        next unless feature_review_path.include?(before_sha)
        link_feature_review_to_ticket(ticket.key, feature_review_path, before_sha, after_sha)
      end
    end
    linked_tickets
  end

  def link_feature_review_to_ticket(ticket_key, old_feature_review_path, before_sha, after_sha)
    new_feature_review_path = old_feature_review_path.sub(before_sha, after_sha)
    message = "[Feature ready for review|#{feature_review_url(new_feature_review_path)}]"
    JiraClient.post_comment(ticket_key, message)
  rescue JiraClient::InvalidKeyError
    @send_error_status = true
    Rails.logger.warn "Failed to post comment to JIRA ticket #{ticket_key}. Ticket might have been deleted."
  rescue StandardError => error
    @send_error_status = true
    Honeybadger.notify(error)
  end

  def feature_review_url(feature_review_path)
    Rails.application.routes.url_helpers.root_url.chomp('/') + feature_review_path
  end

  def post_not_found_status(status_options)
    CommitStatus.new.not_found(status_options)
  end

  def post_error_status(status_options)
    CommitStatus.new.error(status_options)
  end
end
