# frozen_string_literal: true
class HomeController < ApplicationController
  SHA_REGEX = /\b[0-9a-f]{40}\b/

  def index
    @query = params[:q]
    @from_date = params[:from]
    @to_date = params[:to]

    redirect_to root_path(from: Time.zone.today, to: Time.zone.today) if @query.blank? &&
                                                                         @from_date.blank? &&
                                                                         @to_date.blank?

    @tickets = released_ticket_repo.tickets_for_query(build_query_hash(@query, params))
  end

  private

  def released_ticket_repo
    Repositories::ReleasedTicketRepository.new
  end

  def build_query_hash(query, params)
    query_hash = {}
    query_hash[:versions] = query&.scan(SHA_REGEX)

    query_hash[:query_text] = query&.gsub(SHA_REGEX, '')
    query_hash[:from_date] = Date.parse(params[:from]) if params[:from].present?
    query_hash[:to_date] = Date.parse(params[:to]) if params[:to].present?
    query_hash
  end
end
