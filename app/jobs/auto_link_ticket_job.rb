# frozen_string_literal: true

require 'link_ticket'

class AutoLinkTicketJob < ActiveJob::Base
  include Rails.application.routes.url_helpers

  JIRA_TICKET_REGEX = /(?<ticket_key>[A-Z]{2,10}-[1-9][0-9]*)/.freeze

  queue_as :default

  def perform(args)
    head_sha = args.delete(:head_sha)
    repo_name = args.delete(:repo_name)
    branch_name = args.delete(:branch_name)
    title = args.delete(:title)

    jira_key = extract_jira_key(branch_name) || extract_jira_key(title)
    return unless jira_key

    LinkTicket.run(
      jira_key: jira_key,
      feature_review_path: feature_reviews_path(apps: { repo_name => head_sha }),
      root_url: root_url,
    )
  end

  private

  def extract_jira_key(text)
    text[JIRA_TICKET_REGEX, 'ticket_key']
  end
end
