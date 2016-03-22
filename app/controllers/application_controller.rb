class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include Authentication
  helper_method :login_url, :current_user

  before_action :data_maintenance_warning

  def git_repository_loader
    GitRepositoryLoader.from_rails_config
  end

  def event_factory
    @event_factory ||= Factories::EventFactory.from_rails_config
  end

  def data_maintenance_warning
    return unless Rails.configuration.data_maintenance_mode && request.format.html?
    flash.now[:warning] = 'The site is currently undergoing maintenance. '\
                          'Some data may appear out-of-date. ¯\_(ツ)_/¯'
  end

  def path_from_url(url_or_path)
    return nil unless url_or_path.present?
    URI.parse('http://domain.com').merge(url_or_path).request_uri
  rescue URI::InvalidURIError
    nil
  end
end
