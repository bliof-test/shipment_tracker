# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :require_authentication
  skip_before_action :verify_authenticity_token

  def auth0_success_callback
    setup_current_user!
    flash[:info] = "Hello #{current_user.first_name || current_user.email}!"
    redirect_to session[:redirect_path] || root_path
  end

  def auth0_failure_callback
    render plain: 'Sorry - you are not authorized to use this application.', status: :unauthorized
  end

  def destroy
    teardown_current_user
    redirect_to ENV.fetch('AUTH_LOGOUT_URL', "https://#{ENV['AUTH0_DOMAIN']}/logout")
  end
end
