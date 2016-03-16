require 'rails_helper'

RSpec.describe Token do
  describe '.create' do
    it 'autogenerates a value' do
      value = Token.create(source: 'foo').value

      expect(value).to be_a(String)
      expect(value.length).to eq(24)
    end
  end

  describe '.valid?' do
    before do
      Token.create(source: 'circleci', value: 'abc123')
      Token.create(source: 'circleci', value: 'def456')
      Token.create(source: 'circleci', value: nil)
    end

    context 'with a valid token' do
      it 'returns true' do
        expect(Token.valid?('circleci', 'abc123')).to be true
        expect(Token.valid?('circleci', 'def456')).to be true
      end
    end

    context 'with an invalid token' do
      it 'returns false' do
        expect(Token.valid?('circleci', 'xyz789')).to be false
      end
    end

    context 'with a nil token' do
      it 'returns false' do
        expect(Token.valid?('circleci', nil)).to be false
      end
    end
  end

  describe '.revoke' do
    let!(:token) { Token.create(source: 'circleci', value: 'abc123') }

    it 'revokes a token' do
      Token.revoke(token.id)

      expect(Token.valid?('circleci', 'abc123')).to be false
    end
  end

  describe '.sources' do
    let(:event_type_repository) { instance_double(EventTypeRepository) }
    let(:event_types) { [instance_double(EventType, name: 'CircleCI', endpoint: 'circle_ci')] }

    before do
      allow(EventTypeRepository).to receive(:from_rails_config).and_return(event_type_repository)
      allow(event_type_repository).to receive(:external_types).and_return(event_types)
    end

    it 'returns all event enpoints plus github_notifications' do
      expect(Token.sources.map(&:endpoint)).to eq(%w(circle_ci github_notifications))
    end

    it 'returns all event names plus Github Notifications' do
      expect(Token.sources.map(&:name)).to eq(['CircleCI', 'Github Notifications'])
    end
  end

  describe '.source_name' do
    let(:event_type_repository) { instance_double(EventTypeRepository) }
    let(:circleci_type) { EventType.new(endpoint: 'circleci', name: 'CircleCI') }

    before do
      allow(EventTypeRepository).to receive(:from_rails_config).and_return(event_type_repository)
      allow(event_type_repository).to receive(:find_by_endpoint).with('circleci').and_return(circleci_type)
    end

    it 'returns the token source name' do
      expect(Token.new(source: 'circleci').source_name).to eq('CircleCI')
    end

    context 'when source is github_notifications' do
      it 'returns the token source name Github Notifications' do
        expect(Token.new(source: 'github_notifications').source_name).to eq('Github Notifications')
      end
    end
  end
end
