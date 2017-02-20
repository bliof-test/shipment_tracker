# frozen_string_literal: true
require 'deploy'
require 'deploy_alert'
require 'clients/slack'

class DeployAlertJob < ActiveJob::Base
  queue_as :default

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def perform(deploy_attrs)
    current_deploy = Deploy.new(deploy_attrs[:current_deploy])
    previous_deploy = Deploy.new(deploy_attrs[:previous_deploy]) if deploy_attrs[:previous_deploy]

    message = DeployAlert.audit_message(current_deploy, previous_deploy)

    if message
      app_name = current_deploy['app_name']
      releases_url = releases_link(app_name, current_deploy['region'])

      SlackClient.send_deploy_alert(
        message,
        releases_url,
        app_name,
        current_deploy['deployed_by'],
      )

      repo_owners = Repositories::RepoOwnershipRepository.new.owners_of(app_name)

      if repo_owners.present?
        DeployAlertMailer.deploy_alert_email(
          repo_owners: repo_owners,
          repo: app_name,
          region: current_deploy['region'],
          deployer: current_deploy['deployed_by'],
          deployed_at: current_deploy['deployed_at'],
          alert: message,
          releases_url: releases_url,
        ).deliver_now
      end
    end
  end

  def releases_link(app_name, region)
    params = { region: region }
    "#{Rails.application.routes.url_helpers.releases_url}/#{app_name}?#{params.to_query}"
  end
end
