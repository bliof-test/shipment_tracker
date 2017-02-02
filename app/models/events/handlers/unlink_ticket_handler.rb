# frozen_string_literal: true
module Events
  module Handlers
    class UnlinkTicketHandler < TicketHandler
      def apply
        old_versions = ticket.fetch('versions', [])
        new_versions = feature_reviews_from_event.flat_map(&:versions)
        versions_to_remove = old_versions - new_versions
        super.merge(
          'paths' => paths,
          'versions' => versions_to_remove,
          'version_timestamps' => ticket.fetch('version_timestamps', {}).slice(*versions_to_remove),
        )
      end

      private

      def paths
        old_paths = ticket.fetch('paths', [])
        old_paths - feature_reviews_from_event.map(&:path)
      end
    end
  end
end
