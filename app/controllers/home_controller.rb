# frozen_string_literal: true
class HomeController < ApplicationController
  SHA_REGEX = /\b[0-9a-f]{40}\b/

  def index
    return unless params[:preview] == 'true'
    @query = params[:q]

    if @query
      versions = @query.scan(SHA_REGEX)

      text = @query.gsub(SHA_REGEX, '')
      @tickets = released_ticket_repo.tickets_for_query(query_text: text, versions: versions)
    else
      @tickets = []
    end

    render 'dashboard'
  end

  private

  def released_ticket_repo
    Repositories::ReleasedTicketRepository.new
  end
end
