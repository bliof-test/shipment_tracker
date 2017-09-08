# frozen_string_literal: true
require 'virtus'
require 'rack/utils'
require 'addressable/uri'
require 'active_support/core_ext/object'

class FeatureReview
  include Virtus.value_object

  values do
    attribute :path, String
  end

  def app_versions
    query_hash.fetch('apps', {}).select { |_name, version| version.present? }
  end

  def app_names
    app_versions.keys
  end

  def versions
    app_versions.values.sort
  end

  def related_app_versions
    app_versions.each_with_object({}) do |(app, version), hash|
      hash[app] = GitRepositoryLoader.from_rails_config
                                     .load(app)
                                     .get_dependent_commits(version)
                                     .map(&:id) + [version]
    end
  end

  def query_hash
    Rack::Utils.parse_nested_query(URI(path).query)
  end

  def base_path
    Addressable::URI.parse(path).omit(:query).to_s
  end
end
