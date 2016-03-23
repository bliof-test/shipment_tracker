# frozen_string_literal: true
class HomeController < ApplicationController
  def index
    return unless params[:preview] == 'true'

    @query = params[:q]
    @tickets = released_ticket_repo.tickets_for_query(@query)
    render 'dashboard'
  end

  private

  def released_ticket_repo
    Repositories::ReleasedTicketRepository.new
  end
end
