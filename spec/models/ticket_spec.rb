# frozen_string_literal: true

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
    subject { ticket.authorised?(versions, isae_3402_auditable) }

    let(:versions) { %w[abc def] }
    let(:isae_3402_auditable) { false }
    let(:current_time) { Time.current }

    context 'when the ticket was approved after it was linked' do
      let(:ticket_attributes) {
        { approved_at: current_time, version_timestamps: { versions.first => 1.hour.ago } }
      }
      it { is_expected.to be true }
    end

    context 'when the ticket was approved before it was linked' do
      let(:ticket_attributes) {
        { approved_at: 1.hour.ago, version_timestamps: { versions.first => current_time } }
      }
      it { is_expected.to be false }
    end

    context 'when the ticket was approved and linked at the same time' do
      let(:ticket_attributes) {
        { approved_at: current_time, version_timestamps: { versions.first => current_time } }
      }
      it { is_expected.to be true }
    end

    context 'when the ticket has not been approved' do
      let(:ticket_attributes) { { approved_at: nil } }
      it { is_expected.to be false }
    end

    context 'when the ticket has not been linked to the versions under review' do
      let(:ticket_attributes) { { approved_at: current_time, version_timestamps: { 'foo' => 1.hour.ago } } }
      it { is_expected.to be false }
    end

    context 'when the ticket has been linked before approval but no versions are under review' do
      let(:versions) { [] }
      let(:ticket_attributes) {
        { approved_at: current_time, version_timestamps: { versions.first => 1.hour.ago } }
      }
      it { is_expected.to be false }
    end

    context 'when the ticket was approved by the same user who worked on it' do
      let(:email) { 'some.user@example.com' }
      let(:ticket_attributes) {
        { approved_at: current_time,
          version_timestamps: { versions.first => 1.hour.ago },
          authored_by: email,
          approved_by: email }
      }

      context 'and the repos are in the ISAE 3402 critical list' do
        let(:isae_3402_auditable) { true }

        it { is_expected.to be false }
      end

      context 'and the repos are not ISAE 3402 critical' do
        it { is_expected.to be true }
      end
    end
  end

  describe '#authorisation_status' do
    subject { ticket.authorisation_status(versions) }

    let(:versions) { %w[abc def] }

    context 'when ticket is not done' do
      let(:ticket_attributes) { { status: 'Ready for Acceptance' } }

      it 'returns its current status' do
        expect(subject).to eq('Ready for Acceptance')
      end
    end

    context 'when ticket is done' do
      let(:ticket_attributes) { { status: 'Done' } }

      context 'when ticket is authorised' do
        before do
          allow(ticket).to receive(:authorised?).and_return(true)
        end

        it { is_expected.to eq('Done') }
      end

      context 'when ticket is not authorised' do
        before do
          allow(ticket).to receive(:authorised?).and_return(false)
        end

        it { is_expected.to eq('Requires reapproval') }
      end
    end
  end
end
