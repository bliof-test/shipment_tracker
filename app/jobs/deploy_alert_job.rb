class DeployAlertJob < ActiveJob::Base
  queue_as :default

  def perform(deploy)
    message = DeployAlert.audit(deploy)
    Rails.logger.warn message if message
  end
end
