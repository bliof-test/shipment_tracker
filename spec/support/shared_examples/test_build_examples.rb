RSpec.shared_examples 'a test build interface' do
  it { is_expected.to respond_to(:source) }
  it { is_expected.to respond_to(:version) }
  it { is_expected.to respond_to(:success) }
end

RSpec.shared_examples 'a test build subclass' do
  describe '#source' do
    let(:payload) { success_payload }
    it { expect(subject.source).to eq(expected_source) }
  end

  describe '#success' do
    context 'when a failure' do
      let(:payload) { failure_payload }
      it { expect(subject.success).to be false }
    end

    context 'when a success' do
      let(:payload) { success_payload }
      it { expect(subject.success).to be true }
    end

    context 'when invalid' do
      let(:payload) { invalid_payload }
      it { expect(subject.success).to be false }
    end
  end

  describe '#version' do
    context 'when a failure' do
      let(:payload) { failure_payload }
      it { expect(subject.version).to eq(version) }
    end

    context 'when a success' do
      let(:payload) { success_payload }
      it { expect(subject.version).to eq(version) }
    end

    context 'when invalid' do
      let(:payload) { invalid_payload }
      it { expect(subject.version).to eq('unknown') }
    end
  end
end
