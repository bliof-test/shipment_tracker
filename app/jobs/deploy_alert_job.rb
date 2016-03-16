# frozen_string_literal: true
require 'deploy'
require 'deploy_alert'
require 'clients/slack'

class DeployAlertJob < ActiveJob::Base
  queue_as :default

  def perform(deploy_attrs)
    current_deploy = Deploy.new(deploy_attrs[:current_deploy])
    previous_deploy = Deploy.new(deploy_attrs[:previous_deploy]) if deploy_attrs[:previous_deploy]

    message = DeployAlert.audit_message(current_deploy, previous_deploy)

    if message
      app_name = current_deploy['app_name']
      SlackClient.send_deploy_alert(
        message,
        releases_link(app_name, current_deploy['region']),
        app_name,
        current_deploy['deployed_by'],
      )
    end
  end

  def releases_link(app_name, region)
    params = { region: region }
    "#{Rails.application.routes.url_helpers.releases_url}/#{app_name}?#{params.to_query}"
  end
end
