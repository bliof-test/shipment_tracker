# frozen_string_literal: true
require 'build'
require 'events/circle_ci_event'
require 'events/jenkins_event'
require 'snapshots/build'

module Repositories
  class BuildRepository < Base
    APPLICABLE_EVENTS = [Events::CircleCiEvent, Events::JenkinsEvent].freeze

    def initialize(store = Snapshots::Build)
      @store = store
    end

    def apply(event)
      return unless APPLICABLE_EVENTS.any? { |event_type| event.is_a? event_type }

      store.create!(
        success: event.success,
        app_name: event.try(:app_name),
        build_type: event.build_type,
        source: event.source,
        version: event.version,
        url: event.build_url,
        event_created_at: event.created_at,
      )
    end

    def integration_test_results_for(apps:, at: nil)
      test_results_for(apps: apps, build_type: 'integration', at: at)
    end

    def unit_test_results_for(apps:, at: nil)
      test_results_for(apps: apps, build_type: 'unit', at: at)
    end

    private

    def test_results_for(apps:, build_type:, at: nil)
      default_builds = apps.keys.map { |app_name| [app_name, Build.new(build_type: build_type)] }.to_h
      builds = builds(apps.values, build_type, at).map { |build| [apps.invert[build.version], build] }.to_h
      default_builds.merge(builds)
    end

    def builds(versions, build_type, at)
      query = at ? store.arel_table['event_created_at'].lteq(at) : nil
      store.select('DISTINCT ON (version) *').where(
        version: versions, build_type: build_type,
      ).where(query).order('version, id DESC').map { |d|
        Build.new(d.attributes)
      }
    end
  end
end
