# frozen_string_literal: true
class EventsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    event_factory.create(params[:type], request.request_parameters, current_user.email)

    if redirect_path
      flash[:success] = 'Thank you for your submission. It will appear in a moment.'
      redirect_to redirect_path
    end

    self.response_body = 'ok'
  end

  private

  def redirect_path
    @redirect_path ||= path_from_url(params[:return_to])
  end

  def unauthenticated_strategy
    self.status = 403
    self.response_body = 'Forbidden'
  end
end
