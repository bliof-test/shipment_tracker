# frozen_string_literal: true

class HeartBeatController < ApplicationController
  skip_before_action :require_authentication

  def index
    head :ok
  end
end
