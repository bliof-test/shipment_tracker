# frozen_string_literal: true

require 'clients/jira'
require 'honeybadger'
require 'repositories/ticket_repository'

class UpdateTicketLinksJob < ActiveJob::Base
  JIRA_TICKET_REGEX = /(?<ticket_key>[A-Z]{2,10}-[1-9][0-9]*)/.freeze

  queue_as :default

  def perform(args)
    before_sha = args.delete(:before_sha)
    after_sha = args.delete(:after_sha)
    full_repo_name = args.delete(:full_repo_name)
    branch_created = args.delete(:branch_created)
    branch_name = args.delete(:branch_name)

    if branch_created
      check_branch_name_for_ticket_and_link(full_repo_name, branch_name, after_sha)
    elsif branch_name == 'master' || relink_tickets(before_sha, after_sha).empty?
      post_not_found_status(full_repo_name, after_sha)
    elsif @send_error_status
      post_error_status(full_repo_name, after_sha)
    end
  end

  private

  def relink_tickets(before_sha, after_sha)
    ticket_repo = Repositories::TicketRepository.new
    linked_tickets = ticket_repo.tickets_for_versions(before_sha)

    linked_tickets.each do |ticket|
      ticket.paths.each do |feature_review_path|
        next unless feature_review_path.include?(before_sha)

        update_path_and_link_feature_review_to_ticket(ticket.key, feature_review_path, before_sha, after_sha)
      end
    end
  end

  def check_branch_name_for_ticket_and_link(full_repo_name, branch_name, after_sha)
    ticket_key = extract_ticket_key_from_branch_name(branch_name)

    if ticket_key.nil?
      post_not_found_status(full_repo_name, after_sha)
      return
    end

    link_feature_review_to_ticket(ticket_key, url_for_repo_and_sha(full_repo_name, after_sha))
    post_error_status(full_repo_name, after_sha) if @send_error_status
  end

  def update_path_and_link_feature_review_to_ticket(ticket_key, old_feature_review_path, before_sha, after_sha)
    new_feature_review_path = old_feature_review_path.sub(before_sha, after_sha)
    link_feature_review_to_ticket(ticket_key, feature_review_url(new_feature_review_path))
  end

  def link_feature_review_to_ticket(ticket_key, url)
    JiraClient.post_comment(ticket_key, LinkTicket.build_comment(url))
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

  def post_not_found_status(full_repo_name, sha)
    CommitStatus.new(full_repo_name: full_repo_name, sha: sha).not_found
  end

  def post_error_status(full_repo_name, sha)
    CommitStatus.new(full_repo_name: full_repo_name, sha: sha).error
  end

  def extract_ticket_key_from_branch_name(branch_name)
    matches = branch_name.match(JIRA_TICKET_REGEX)
    matches[:ticket_key] if matches
  end

  def url_for_repo_and_sha(full_repo_name, sha)
    CommitStatus.new(full_repo_name: full_repo_name, sha: sha).target_url
  end
end
