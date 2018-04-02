# frozen_string_literal: true

require 'events/base_event'

module Events
  class CircleCiEvent < Events::BaseEvent
    def source
      'CircleCi'
    end

    def build_type
      details.dig('payload', 'build_type') || 'unit'
    end

    def build_url
      details.dig('payload', 'build_url')
    end

    def success
      details.dig('payload', 'outcome') == 'success'
    end

    def app_name
      details.dig('payload', 'app_name')
    end

    def version
      details.dig('payload', 'vcs_revision') || 'unknown'
    end
  end
end
