# frozen_string_literal: true
require 'clients/jira'

Before('@disable_jira_client') do
  allow(JiraClient).to receive(:post_comment)
end
