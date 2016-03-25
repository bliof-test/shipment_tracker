# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Events::JiraEvent do
  describe '#datetime' do
    it 'returns a TimeWithZone in UTC' do
      event = build(:jira_event, timestamp: 1458842541458)
      expected_time = Time.zone.parse('Thu, 24 Mar 2016 18:02:21 UTC')

      expect(event.datetime).to eq(expected_time)
    end

    it 'falls back to created_at when timestamp missing' do
      time = 1.hour.ago.change(usec: 0)
      event = build(:jira_event, timestamp: nil, created_at: time)

      expect(event.datetime).to eq(time)
    end
  end

  describe '#approval?' do
    context 'when the status changes from unapproved to approved' do
      it 'returns true' do
        expect(build(:jira_event, :approved).approval?).to be true
      end
    end

    context 'when the status changes from approved to approved' do
      it 'returns false' do
        expect(build(:jira_event, :deployed).approval?).to be false
      end
    end

    context 'when the status changes from unapproved to unapproved' do
      it 'returns false' do
        expect(build(:jira_event, :development_completed).approval?).to be false
      end
    end

    context 'when the status changes from approved to unapproved' do
      it 'returns false' do
        expect(build(:jira_event, :rejected).approval?).to be false
      end
    end
  end

  describe '#unapproval?' do
    context 'when the status changes from unapproved to approved' do
      it 'returns false' do
        expect(build(:jira_event, :approved).unapproval?).to be false
      end
    end

    context 'when the status changes from approved to approved' do
      it 'returns false' do
        expect(build(:jira_event, :deployed).unapproval?).to be false
      end
    end

    context 'when the status changes from unapproved to unapproved' do
      it 'returns false' do
        expect(build(:jira_event, :development_completed).unapproval?).to be false
      end
    end

    context 'when the status changes from approved to unapproved' do
      it 'returns true' do
        expect(build(:jira_event, :rejected).unapproval?).to be true
      end
    end
  end
end
