require 'clients/jira'
require 'git_repository_location'
require 'repositories/ticket_repository'

class HandlePushEvent
  include SolidUseCase

  steps :update_remote_head, :relink_tickets

  def update_remote_head(payload)
    git_repository_location = GitRepositoryLocation.find_by_full_repo_name(payload.full_repo_name)
    return fail :repo_not_found unless git_repository_location
    git_repository_location.update(remote_head: payload.after_sha)
    continue(payload)
  end

  def relink_tickets(payload)
    ticket_repo = Repositories::TicketRepository.new
    linked_tickets = ticket_repo.tickets_for_versions(payload.before_sha)
    return fail :no_previously_linked_tickets if linked_tickets.empty?

    linked_tickets.each do |ticket|
      ticket.paths.each do |feature_review_path|
        next unless feature_review_path.include?(payload.before_sha)
        link_feature_review_to_ticket(ticket.key, feature_review_path, payload.before_sha, payload.after_sha)
      end
    end

    continue(payload)
  end

  private

  def link_feature_review_to_ticket(ticket_key, old_feature_review_path, before_sha, after_sha)
    new_feature_review_path = old_feature_review_path.sub(before_sha, after_sha)
    message = "[Feature ready for review|#{feature_review_url(new_feature_review_path)}]"
    JiraClient.post_comment(ticket_key, message)
  end

  def feature_review_url(feature_review_path)
    Rails.application.routes.url_helpers.root_url(protocol: ENV.fetch('PROTOCOL', 'https'))
         .chomp('/') + feature_review_path
  end
end
