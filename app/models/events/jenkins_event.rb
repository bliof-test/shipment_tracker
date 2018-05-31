# frozen_string_literal: true

require 'events/base_event'

module Events
  class JenkinsEvent < Events::BaseEvent
    def source
      'Jenkins'
    end

    def build_type
      details.dig('build', 'build_type') || 'unit'
    end

    def build_url
      details.dig('build', 'full_url')
    end

    def success
      details.dig('build', 'status')&.downcase == 'success'
    end

    def app_name
      details.dig('build', 'app_name')
    end

    def version
      details.dig('build', 'scm', 'commit') || 'unknown'
    end
  end
end
