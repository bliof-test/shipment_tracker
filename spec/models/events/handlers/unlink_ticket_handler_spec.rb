# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Events::Handlers::UnlinkTicketHandler do
  let(:time) { Time.current.change(usec: 0) }

  let(:path1) { feature_review_path(app1: 'one') }

  let(:url2) { feature_review_url(app2: 'two') }
  let(:path2) { feature_review_path(app2: 'two') }

  describe '#apply' do
    it 'removes the link' do
      time1 = time - 3.hours
      ticket = {
        'key' => 'JIRA-1',
        'paths' => [path1, path2],
        'versions' => %w(one two),
        'version_timestamps' => { 'one' => time1, 'two' => time - 2.hours },
      }
      unlink_2_event = build(
        :jira_event,
        key: 'JIRA-1',
        comment_body: UnlinkTicket.build_comment(url2),
        created_at: time - 1.hour,
      )

      new_ticket = described_class.new(ticket, unlink_2_event).apply
      expect(new_ticket).to include(
        'key' => 'JIRA-1',
        'paths' => [path1],
        'versions' => %w(one),
        'version_timestamps' => { 'one' => time1 },
      )
    end
  end
end
