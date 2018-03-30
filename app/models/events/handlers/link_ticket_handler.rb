# frozen_string_literal: true

module Events
  module Handlers
    class LinkTicketHandler < TicketHandler
      def apply
        super.merge(
          'paths' => paths,
          'versions' => versions,
          'version_timestamps' => version_timestamps,
        )
      end

      private

      def paths
        old_paths = ticket.fetch('paths', [])
        new_paths = feature_reviews_from_event.map(&:path)
        old_paths.concat(new_paths).uniq
      end

      def versions
        old_versions = ticket.fetch('versions', [])
        new_versions = feature_reviews_from_event.flat_map(&:versions)
        old_versions.concat(new_versions).uniq
      end

      def version_timestamps
        old_version_timestamps = ticket.fetch('version_timestamps', {})
        versions = feature_reviews_from_event.flat_map(&:versions)
        new_version_timestamps = versions.each_with_object({}) { |version, hash|
          hash[version] = event.created_at
        }
        new_version_timestamps.merge(old_version_timestamps)
      end
    end
  end
end
