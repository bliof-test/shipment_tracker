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

    if branch_created || commit_on_master?(full_repo_name, after_sha) ||
       relink_tickets(before_sha, after_sha).empty?
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

        link_feature_review_to_ticket(ticket.key, feature_review_path, before_sha, after_sha)
      end
    end
  end

  def link_feature_review_to_ticket(ticket_key, old_feature_review_path, before_sha, after_sha)
    new_feature_review_path = old_feature_review_path.sub(before_sha, after_sha)
    JiraClient.post_comment(ticket_key, LinkTicket.build_comment(feature_review_url(new_feature_review_path)))
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
    CommitStatusUpdateJob.perform_later(
      full_repo_name: full_repo_name,
      sha: sha,
      method: 'not_found',
    )
  end

  def post_error_status(full_repo_name, sha)
    CommitStatusUpdateJob.perform_later(
      full_repo_name: full_repo_name,
      sha: sha,
      method: 'error',
    )
  end

  def commit_on_master?(full_repo_name, sha)
    git_repo = GitRepositoryLoader.from_rails_config.load(full_repo_name.split('/')[1], update_repo: true)

    git_repo.commit_on_master?(sha)
  end
end
