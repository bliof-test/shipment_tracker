# frozen_string_literal: true
module Events
  module Handlers
    class TicketHandler
      def initialize(ticket, event)
        @ticket = ticket
        @event = event
      end

      def apply
        ticket.merge(
          'key' => event.key,
          'summary' => event.summary,
          'status' => event.status,
          'event_created_at' => event.created_at,
          'approved_at' => merge_approved_at(ticket, event),
          'approved_by_email' => merge_approved_by_email(ticket, event),
        )
      end

      protected

      attr_reader :ticket, :event

      def feature_reviews_from_event
        Factories::FeatureReviewFactory.new.create_from_text(event.comment)
      end

      private

      def merge_approved_at(last_ticket, event)
        if event.approval?
          event.created_at
        elsif last_ticket.present? && Ticket.new(status: event.status).approved?
          last_ticket['approved_at']
        end
      end

      def merge_approved_by_email(last_ticket, event)
        if event.approval? && event.details['user']
          event.approved_by_email
        elsif last_ticket.present? && Ticket.new(status: event.status).approved?
          last_ticket['approved_by_email']
        end
      end
    end
  end
end
