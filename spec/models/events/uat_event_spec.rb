require 'rails_helper'

RSpec.describe Events::UatEvent do
  subject { described_class.new(details: payload) }

  context 'when given a valid payload' do
    let(:payload) {
      {
        'success' => true,
        'test_suite_version' => 'ab91d954a51ddc74e29e7582d9a2efe8bb6d480f',
        'server' => 'uat.example.com',
      }
    }

    it 'returns the correct values' do
      expect(subject.test_suite_version).to eq('ab91d954a51ddc74e29e7582d9a2efe8bb6d480f')
      expect(subject.server).to eq('uat.example.com')
      expect(subject.success).to be(true)
    end
  end

  context 'when given an invalid payload' do
    let(:payload) {
      {
        'bad' => 'news',
      }
    }

    it 'returns the correct values' do
      expect(subject.test_suite_version).to be_nil
      expect(subject.server).to be_nil
      expect(subject.success).to be(false)
    end
  end
end
