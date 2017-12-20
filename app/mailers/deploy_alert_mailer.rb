# frozen_string_literal: true
class DeployAlertMailer < ApplicationMailer
  # rubocop:disable Metrics/ParameterLists
  def deploy_alert_email(repo_owners:, repo:, region:, deployer:, deployed_at:, alert:, releases_url:)
    owner_emails = RepoAdmin.to_mail_address_list(repo_owners).format

    @repo = repo
    @region = region
    @deployer = deployer
    @deployed_at = deployed_at.strftime('%F %T %z')
    @alert = alert
    @releases_url = releases_url

    mail(
      from: Rails.configuration.deploy_alert_email,
      to: owner_emails,
      subject: "Deploy alert for #{@repo} - #{@deployed_at}",
    )
  end
end
