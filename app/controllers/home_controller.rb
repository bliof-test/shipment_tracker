# frozen_string_literal: true
class HomeController < ApplicationController
  SHA_REGEX = /\b[0-9a-f]{40}\b/

  def index
    @query = params[:q]
    @from_date = params[:from]
    @to_date = params[:to]

    search_for_tickets_deployed_today if empty_search?

    @tickets = Repositories::ReleasedTicketRepository.new.tickets_for_query(query_options)
  end

  private

  def search_for_tickets_deployed_today
    redirect_to root_path(from: Time.zone.today, to: Time.zone.today)
  end

  def empty_search?
    @query.blank? && @from_date.blank? && @to_date.blank?
  end

  def query_options(options = {})
    options[:query_text] = @query&.gsub(SHA_REGEX, '')
    options[:versions] = @query&.scan(SHA_REGEX)
    options[:from_date] = Date.parse(@from_date) if @from_date.present?
    options[:to_date] = Date.parse(@to_date) if @to_date.present?
    options
  end
end
