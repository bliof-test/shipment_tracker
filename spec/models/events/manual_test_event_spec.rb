require 'rails_helper'

RSpec.describe Events::ManualTestEvent do
  subject(:event) { described_class.new(details: details) }

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
    it 'returns the status' do
      expect(event.accepted?).to be true
    end

    context 'when there is no status' do
      let(:details) { default_details.except('status') }

      it 'returns nil' do
        expect(event.accepted?).to be false
      end
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
