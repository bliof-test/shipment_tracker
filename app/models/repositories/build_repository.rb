# frozen_string_literal: true
require 'build'
require 'events/circle_ci_event'
require 'events/jenkins_event'
require 'snapshots/build'

module Repositories
  class BuildRepository < Base
    def initialize(store = Snapshots::Build)
      @store = store
    end

    def apply(event)
      return unless event.is_a?(Events::CircleCiEvent) || event.is_a?(Events::JenkinsEvent)

      store.create!(
        success: event.success,
        source: event.source,
        version: event.version,
        event_created_at: event.created_at,
      )
    end

    def builds_for(apps:, at: nil)
      default_builds = apps.keys.map { |app_name| [app_name, Build.new] }.to_h
      builds = builds(apps.values, at).map { |build| [apps.invert[build.version], build] }.to_h
      default_builds.merge(builds)
    end

    private

    def builds(versions, at)
      query = at ? store.arel_table['event_created_at'].lteq(at) : nil
      store.select('DISTINCT ON (version) *').where(
        version: versions,
      ).where(query).order('version, id DESC').map { |d|
        Build.new(d.attributes)
      }
    end
  end
end
