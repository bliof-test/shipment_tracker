require 'events/base_event'

module Events
  class CircleCiEvent < Events::BaseEvent
    def source
      'CircleCi'
    end

    def success
      status = details
               .fetch('payload', {})
               .fetch('outcome', nil)

      status == 'success'
    end

    def version
      details.fetch('payload', {}).fetch('vcs_revision', 'unknown')
    end
  end
end
