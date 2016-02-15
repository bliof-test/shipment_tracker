class DeployAlertJob < ActiveJob::Base
  queue_as :default

  def perform(deploy)
    message = DeployAlert.audit(deploy)
    return unless message
    Rails.logger.warn message
    notifier = SlackNotifier.new
    notifier.send(message, '#blackbat')
  end
end
