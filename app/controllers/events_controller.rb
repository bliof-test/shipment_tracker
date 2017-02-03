# frozen_string_literal: true
class EventsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    event =
      event_factory.build(
        endpoint: params[:type],
        payload: request.request_parameters.except('event'),
        user: current_user,
      )

    if event.save
      successful_response(event)
    else
      failure_response(event)
    end
  end

  private

  def successful_response(_)
    if redirect_path
      flash[:success] = 'Thank you for your submission. It will appear in a moment.'
      redirect_to redirect_path
    else
      render status: 200, text: 'ok'
    end
  end

  def failure_response(event)
    Rails.logger.info("Could not create event: #{event.inspect}")

    if event.errors[:base].include?('forbidden')
      unauthenticated_strategy
    elsif redirect_path
      flash[:error] = event.errors.full_messages
      redirect_to redirect_path
    else
      render status: 400, text: "Error - #{event.errors.full_messages}"
    end
  end

  def redirect_path
    @redirect_path ||= path_from_url(params[:return_to])
  end

  def unauthenticated_strategy
    render status: 403, text: 'Forbidden'
  end
end
