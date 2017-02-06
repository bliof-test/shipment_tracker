# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Events::Handlers::LinkTicketHandler do
  let(:time) { Time.current.change(usec: 0) }

  let(:url1) { feature_review_url(app1: 'one') }
  let(:path1) { feature_review_path(app1: 'one') }
  let(:time1) { time - 3.hours }

  let(:path2) { feature_review_path(app2: 'two') }
  let(:url2) { feature_review_url(app2: 'two') }
  let(:time2) { time - 2.hours }

  describe '#apply' do
    it 'adds link references' do
      events = [
        build(:jira_event, key: 'JIRA-1', comment_body: LinkTicket.build_comment(url1), created_at: time1),
        build(:jira_event, key: 'JIRA-1', comment_body: LinkTicket.build_comment(url2), created_at: time2),
        build(:jira_event, key: 'JIRA-1', comment_body: LinkTicket.build_comment(url1), created_at: time - 1.hour),
      ]

      final_ticket = events.reduce({}) { |ticket, event| described_class.new(ticket, event).apply }
      expect(final_ticket).to match(
        hash_including(
          'key' => 'JIRA-1',
          'paths' => [path1, path2],
          'versions' => %w(one two),
          'version_timestamps' => { 'one' => time1, 'two' => time2 },
        ),
      )
    end
  end
end
