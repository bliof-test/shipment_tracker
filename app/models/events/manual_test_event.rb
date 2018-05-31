# frozen_string_literal: true

require 'events/base_event'

module Events
  class ManualTestEvent < Events::BaseEvent
    def apps
      details.fetch('apps', [])
    end

    def versions
      apps.map { |app| app.fetch('version') }
    end

    def email
      details.fetch('email', nil)
    end

    def comment
      details.fetch('comment', '')
    end

    def accepted?
      details.fetch('status', nil)&.downcase == 'success'
    end
  end
end
