# frozen_string_literal: true
require 'events/base_event'

module Events
  class JenkinsEvent < Events::BaseEvent
    def source
      'Jenkins'
    end

    def success
      details.dig('build', 'status') == 'SUCCESS'
    end

    def version
      details.dig('build', 'scm', 'commit') || 'unknown'
    end
  end
end
