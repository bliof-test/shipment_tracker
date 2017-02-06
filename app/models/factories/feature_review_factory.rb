# frozen_string_literal: true
require 'rack/utils'
require 'uri'

require 'feature_review'

module Factories
  class FeatureReviewFactory
    QUERY_PARAM_WHITELIST = %w(apps uat_url).freeze

    def create_from_text(text)
      URI.extract(text, %w(http https))
         .map { |uri| parse_uri(uri) }
         .compact
         .select { |url| url.path == '/feature_reviews' }
         .map { |url| create_from_url_string(url) }
    end

    def create_from_tickets(tickets)
      map_paths(tickets).map { |path| create_from_url_string(path) }
    end

    def create_from_url_string(url)
      uri = Addressable::URI.parse(url).normalize
      query_hash = Rack::Utils.parse_nested_query(uri.query)
      apps = query_hash.fetch('apps', {})
      versions = get_app_versions(apps)
      create(
        path: whitelisted_path(uri, query_hash),
        versions: versions,
      )
    end

    def create_from_apps(apps)
      uri = Addressable::URI.parse('/feature_reviews').normalize
      query_hash = { 'apps' => apps }

      last_staging_deploy = deploy_repository.last_staging_deploy_for_versions(get_app_versions(apps))
      query_hash['uat_url'] = last_staging_deploy.server if last_staging_deploy

      create(
        path: whitelisted_path(uri, query_hash),
        versions: get_app_versions(apps),
      )
    end

    private

    def create(attrs)
      FeatureReview.new(attrs)
    end

    def get_app_versions(apps)
      apps.values.reject(&:blank?)
    end

    def whitelisted_path(uri, query_hash)
      "#{uri.path}?#{query_hash.extract!(*QUERY_PARAM_WHITELIST).to_query}"
    end

    def map_paths(tickets)
      tickets.flat_map(&:paths).uniq
    end

    def parse_uri(uri)
      URI.parse(clean_uri(uri))
    rescue URI::InvalidURIError
      nil
    end

    def clean_uri(uri)
      trailing_junk = uri[/.*\w(\W*)$/, 1]
      uri.chomp(trailing_junk)
    end

    def deploy_repository
      Repositories::DeployRepository.new
    end
  end
end
