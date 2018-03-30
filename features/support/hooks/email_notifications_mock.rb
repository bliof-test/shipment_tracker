# frozen_string_literal: true

Before('@mock_email_notifications') do
  mailer_stub = double('Mailer', deliver_now: true, deliver_later: true)

  allow(DeployAlertMailer).to receive(:deploy_alert_email).and_return(mailer_stub)
end
