# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Events::ManualTestEvent do
  def event_for(details)
    described_class.new(details: details)
  end

  subject(:event) { event_for(details) }

  let(:apps) { [{ 'name' => 'frontend', 'version' => 'abc' }] }
  let(:email) { 'alice@example.com' }
  let(:comment) { 'LGTM' }
  let(:status) { 'success' }

  let(:default_details) {
    {

      'apps' => apps,
      'email' => email,
      'status' => status,
      'comment' => comment,
    }
  }

  let(:details) { default_details }

  describe '#apps' do
    it 'returns the apps list' do
      expect(event.apps).to eq(apps)
    end

    context 'when there are no apps' do
      let(:details) { default_details.except('apps') }

      it 'returns an empty list' do
        expect(event.apps).to eq([])
      end
    end
  end

  describe '#comment' do
    it 'returns the comment' do
      expect(event.email).to eq(email)
    end

    context 'when there is no comment' do
      let(:details) { default_details.except('comment') }

      it 'returns nil' do
        expect(event.comment).to eq('')
      end
    end
  end

  describe '#accepted?' do
    it 'is true for "success"' do
      expect(event_for(details.merge(status: 'success')).accepted?).to be true
    end

    it 'is true for SUccess' do
      expect(event_for(details.merge(status: 'SUccess')).accepted?).to be true
    end

    it 'is false for "failure"' do
      expect(event_for(details.merge(status: 'failure')).accepted?).to be false
    end

    it 'is false if there is no status' do
      expect(event_for(details.except('status')).accepted?).to be false
    end
  end

  describe '#email' do
    it 'returns the email' do
      expect(event.email).to eq(email)
    end

    context 'when there is no email' do
      let(:details) { default_details.except('email') }

      it 'returns nil' do
        expect(event.email).to be_nil
      end
    end
  end
end
