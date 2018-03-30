# frozen_string_literal: true

require 'spec_helper'
require 'feature_review'

RSpec.describe FeatureReview do
  let(:base_path) { '/feature_reviews' }

  describe '#app_versions' do
    let(:path) { "#{base_path}?apps%5Bapp1%5D=xxx&apps%5Bapp2%5D=yyy&apps%5Bapp3%5D" }

    subject { FeatureReview.new(path: path).app_versions }

    it { is_expected.to eq('app1' => 'xxx', 'app2' => 'yyy') }
  end

  describe '#app_names' do
    let(:path) { "#{base_path}?apps%5Bapp1%5D=xxx&apps%5Bapp2%5D=yyy&apps%5Bapp3%5D" }

    subject { FeatureReview.new(path: path).app_names }

    it { is_expected.to eq(%w[app1 app2]) }
  end

  describe '#base_path' do
    let(:path) { '/something?apps%5Bapp1%5D=xxx&apps%5Bapp2%5D=yyy' }

    subject { FeatureReview.new(path: path, versions: %w[xxx yyy]).base_path }

    it { is_expected.to eq('/something') }
  end

  describe '#query_hash' do
    let(:path) { '/something?apps%5Bapp1%5D=xxx&apps%5Bapp2%5D=yyy' }

    subject { FeatureReview.new(path: path, versions: %w[xxx yyy]).query_hash }

    it { is_expected.to eq('apps' => { 'app1' => 'xxx', 'app2' => 'yyy' }) }
  end
end
