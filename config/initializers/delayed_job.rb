# frozen_string_literal: true

unless Rails.env.test?
  require_relative '../prometheus_client'

  require 'prometheus_exporter/instrumentation'
  PrometheusExporter::Instrumentation::DelayedJob.register_plugin(client: PrometheusExporter::Client.default)
end

Delayed::Worker.sleep_delay = 2
Delayed::Worker.max_attempts = 10
Delayed::Worker.max_run_time = 5.minutes

module Sinatra
  module SessionHelper
    def valid_session?
      session[:expires_at] && Time.current < session[:expires_at].to_time(:local)
    end
  end

  module DelayedJobAuth
    def self.registered(app)
      app.helpers SessionHelper

      app.before do
        pass if request.path_info =~ /auth/
        redirect to '/auth/auth0' unless valid_session?
      end

      app.get '/auth/auth0/callback' do
        session[:expires_at] = Time.current + 24.hours
        redirect to '/'
      end
    end
  end

  register DelayedJobAuth
end

DelayedJobWeb.register Sinatra::DelayedJobAuth unless Rails.env.development?
