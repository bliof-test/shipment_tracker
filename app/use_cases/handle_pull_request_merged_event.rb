# frozen_string_literal: true

require 'handle_pull_request_event_base'

class HandlePullRequestMergedEvent < HandlePullRequestEventBase
  steps :validate, :update_remote_head
end
