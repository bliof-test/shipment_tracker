# frozen_string_literal: true
class HomeController < ApplicationController
  SHA_REGEX = /\b[0-9a-f]{40}\b/

  def index
    return unless params[:preview] == 'true'
    @query = params[:q]
    @from_date = params[:from]
    @to_date = params[:to]

    if @query
      query_hash = {}
      query_hash[:versions] = @query.scan(SHA_REGEX)

      query_hash[:query_text] = @query.gsub(SHA_REGEX, '')
      query_hash[:from_date] = DateTime.parse(params[:from]).beginning_of_day if params[:from].present?
      query_hash[:to_date] = DateTime.parse(params[:to]).end_of_day if params[:to].present?
      @tickets = released_ticket_repo.tickets_for_query(query_hash)
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
