# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Release do
  let(:commit) { GitCommit.new(id: 'abc') }
  let(:feature_review1) { instance_double(FeatureReviewWithStatuses) }
  let(:feature_review2) { instance_double(FeatureReviewWithStatuses) }
  let(:feature_reviews) { [feature_review1, feature_review2] }

  subject(:release) { described_class.new(commit: commit) }

  describe '#version' do
    it 'returns the commit id' do
      expect(release.version).to eq('abc')
    end
  end

  describe '#authorised?' do
    subject(:release) { Release.new(feature_reviews: feature_reviews) }

    it 'returns true if any of its feature reviews are authorised' do
      allow(feature_review1).to receive(:authorised?).and_return(true)
      allow(feature_review2).to receive(:authorised?).and_return(false)
      expect(release.authorised?).to be true
    end

    it 'returns false if none of its feature reviews are authorised' do
      allow(feature_review1).to receive(:authorised?).and_return(false)
      allow(feature_review2).to receive(:authorised?).and_return(false)
      expect(release.authorised?).to be false
    end
  end
end
