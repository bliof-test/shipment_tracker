# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Snapshots::GitRepositoryLocation do
  describe '.for' do
    it 'returns the snapshot for specific repository name' do
      snapshot = create(:git_repository_location_snapshot, name: 'test-repo')

      expect(described_class.for('test-repo')).to eq(snapshot)
    end

    context 'when there is no snapshot' do
      it 'it returns a non-persisted one with the correct name' do
        repo = double('Repo', name: 'test-repo')

        snapshot = described_class.for(repo.name)

        expect(snapshot.name).to eq('test-repo')
        expect(snapshot).to_not be_persisted
      end
    end
  end
end
