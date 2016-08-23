# frozen_string_literal: true
Rack::Timeout.timeout = Rails.env.development? ? 0 : 29 # seconds
