# frozen_string_literal: true
require 'events/base_event'

module Events
  class CircleCiEvent < Events::BaseEvent
    def source
      'CircleCi'
    end

    def success
      details.dig('payload', 'outcome') == 'success'
    end

    def version
      details.dig('payload', 'vcs_revision') || 'unknown'
    end
  end
end
