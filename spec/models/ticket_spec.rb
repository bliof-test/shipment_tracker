require 'rails_helper'

RSpec.describe Ticket do
  subject(:ticket) { Ticket.new(ticket_attributes) }

  describe '#approved?' do
    it 'returns true for approved statuses' do
      Rails.application.config.approved_statuses.each do |status|
        expect(Ticket.new(status: status).approved?).to be true
      end
    end

    it 'returns false for any other status' do
      expect(Ticket.new(status: 'any').approved?).to be false
    end

    it 'returns false if status not set' do
      expect(Ticket.new(status: nil).approved?).to be false
    end
  end

  describe '#authorised?' do
    subject { ticket.authorised? }

    context 'when the ticket was approved after it was linked' do
      let(:ticket_attributes) { { approved_at: Time.current, event_created_at: 1.hour.ago } }
      it { is_expected.to be false }
    end

    context 'when the ticket was approved before it was linked' do
      let(:ticket_attributes) { { approved_at: 1.hour.ago, event_created_at: Time.current } }
      it { is_expected.to be true }
    end

    context 'when the ticket was approved and linked at the same time' do
      let(:current_time) { Time.current }
      let(:ticket_attributes) { { approved_at: current_time, event_created_at: current_time } }
      it { is_expected.to be false }
    end

    context 'when the ticket has not been approved' do
      let(:ticket_attributes) { { approved_at: nil, event_created_at: Time.current } }
      it { is_expected.to be false }
    end
  end
end
