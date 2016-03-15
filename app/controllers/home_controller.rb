class HomeController < ApplicationController
  skip_before_action :require_authentication

  def index
    @query = params[:q]
    # TODO: remove filter selection below [..]
    @tickets = released_ticket_repo.tickets_for_query(@query)[1..2].reverse
    render 'dashboard' if params[:preview] == 'true'
  end

  private

  def released_ticket_repo
    Repositories::ReleasedTicketRepository.new
  end
end
