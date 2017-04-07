# frozen_string_literal: true
require 'deploy'
require 'deploy_alert'
require 'clients/slack'

class DeployAlertJob < ActiveJob::Base
  queue_as :default

  def perform(deploy_attrs)
    Auditor.new(deploy_attrs).audit
  end

  class Auditor
    def initialize(args = {})
      @current_deploy = Deploy.new(args[:current_deploy])
      @previous_deploy = Deploy.new(args[:previous_deploy]) if args[:previous_deploy]
    end

    attr_reader :current_deploy, :previous_deploy

    def app_name
      current_deploy['app_name']
    end

    def region
      current_deploy['region']
    end

    def deployer
      current_deploy['deployed_by']
    end

    def deployed_at
      current_deploy['deployed_at']
    end

    def deploy_uuid
      current_deploy['uuid']
    end

    def audit
      message = DeployAlert.audit_message(current_deploy, previous_deploy)

      return unless message

      create_deploy_alert_event(message)
      notify_slack(message)
      notify_repo_owners(message)
    end

    def create_deploy_alert_event(message)
      if deploy_uuid.present?
        Events::DeployAlertEvent.create!(
          details: { deploy_uuid: deploy_uuid, message: message },
        )
      else
        Rails.logger.warn "No uuid for #{current_deploy.inspect}"
      end
    end

    def notify_slack(message)
      SlackClient.send_deploy_alert(message, releases_url, app_name, deployer)
    end

    def notify_repo_owners(message)
      repo_owners = Repositories::RepoOwnershipRepository.new.owners_of(app_name)

      return if repo_owners.blank?

      DeployAlertMailer.deploy_alert_email(
        repo_owners: repo_owners,
        repo: app_name,
        region: region,
        deployer: deployer,
        deployed_at: deployed_at,
        alert: message,
        releases_url: releases_url,
      ).deliver_now
    end

    def releases_url
      params = { region: region }
      "#{Rails.application.routes.url_helpers.releases_url}/#{app_name}?#{params.to_query}"
    end
  end

  private_constant :Auditor
end
