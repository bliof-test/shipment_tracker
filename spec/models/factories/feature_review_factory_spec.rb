# frozen_string_literal: true
require 'rails_helper'
require 'addressable/uri'
require 'ticket'

RSpec.describe Factories::FeatureReviewFactory do
  subject(:factory) { described_class.new }

  before do
    repository = instance_double(GitRepository, get_dependent_commits: [])

    allow_any_instance_of(GitRepositoryLoader).to receive(:load).with('app1').and_return(repository)
    allow_any_instance_of(GitRepositoryLoader).to receive(:load).with('foo').and_return(repository)
    allow_any_instance_of(GitRepositoryLoader).to receive(:load).with('a').and_return(repository)
  end

  describe '#create_from_text' do
    let(:url1) { full_url('apps[app1]' => 'abc', 'apps[app2]' => 'def') }
    let(:url2) { full_url('apps[app1]' => 'abc') }

    let(:text) {
      <<-EOS
        complex feature review #{url1}
        simple feature review #{url2}
      EOS
    }

    let(:feature_review1) {
      FeatureReview.new(
        path: '/feature_reviews?apps%5Bapp1%5D=abc&apps%5Bapp2%5D=def',
        versions: %w(abc def),
      )
    }

    let(:feature_review2) {
      FeatureReview.new(
        path: '/feature_reviews?apps%5Bapp1%5D=abc',
        versions: %w(abc),
      )
    }

    subject(:feature_reviews) { factory.create_from_text(text) }

    it 'returns an array of Feature Reviews for each FR URL in the given text' do
      expect(feature_reviews).to match_array([feature_review1, feature_review2])
    end

    context 'when a FR URL contains JIRA link markup' do
      let(:text) { "please review [FR|#{url1}]" }

      it 'strips the markup' do
        expect(feature_reviews).to match_array([feature_review1])
      end
    end

    context 'when a FR URL contains JIRA link markup, is between parentheses, and ends with a dot' do
      let(:text) { "([FR|#{url2}])." }

      it 'strips the trailing non-word characters' do
        expect(feature_reviews).to match_array([feature_review2])
      end
    end

    context 'when a FR URL contains non-whitelisted query params' do
      let(:url) { full_url('non-whitelisted' => 'ignoreme', 'apps[foo]' => 'bar') }
      let(:text) { "please review #{url}" }

      it 'filters them out' do
        expect(feature_reviews).to match_array([
          FeatureReview.new(path: '/feature_reviews?apps%5Bfoo%5D=bar', versions: %w(bar)),
        ])
      end
    end

    context 'when a URL has an irrelevant path' do
      let(:text) { 'irrelevant path http://localhost/not_important?apps[junk]=999' }

      it 'ignores the URL' do
        expect(feature_reviews).to be_empty
      end
    end

    context 'when a URL is unparseable' do
      let(:text) { 'unparseable http://foo.io/feature_reviews#[bad[' }

      it 'ignores the URL' do
        expect(feature_reviews).to be_empty
      end
    end

    context 'when a URL contains an unknown schema' do
      let(:text) { 'foo:/feature_reviews' }

      it 'ignores it' do
        expect(feature_reviews).to be_empty
      end
    end
  end

  describe '#create_from_url_string' do
    it 'returns a FeatureReview with the attributes from the url' do
      actual_url = full_url(
        'apps[a]' => '123',
        'apps[b]' => '456',
      )
      expected_path = '/feature_reviews?apps%5Ba%5D=123&apps%5Bb%5D=456'

      feature_review = factory.create_from_url_string(actual_url)
      expect(feature_review.versions).to eq(%w(123 456))
      expect(feature_review.path).to eq(expected_path)
    end

    it 'excludes non-whitelisted query parameters' do
      actual_url = full_url(
        'apps[a]' => '123',
        'time'    => Time.current.utc.to_s,
        'some'    => 'non-whitelisted',
      )
      expected_path = '/feature_reviews?apps%5Ba%5D=123'

      feature_review = factory.create_from_url_string(actual_url)
      expect(feature_review.versions).to eq(%w(123))
      expect(feature_review.path).to eq(expected_path)
    end

    it 'only captures non-blank versions in the url' do
      actual_url = full_url(
        'apps[a]' => '123',
        'apps[b]' => '',
      )
      expected_path = '/feature_reviews?apps%5Ba%5D=123&apps%5Bb%5D='

      feature_review = factory.create_from_url_string(actual_url)
      expect(feature_review.versions).to eq(['123'])
      expect(feature_review.path).to eq(expected_path)
    end
  end

  describe '#create_from_tickets' do
    context 'when no tickets are given' do
      let(:tickets) { [] }

      it 'returns empty' do
        expect(factory.create_from_tickets(tickets)).to be_empty
      end
    end

    context 'when given tickets with paths' do
      let(:ticket1) {
        Ticket.new(paths: [feature_review_path(app1: 'abc', app2: 'def'), feature_review_path(app1: 'abc')])
      }
      let(:ticket2) {
        Ticket.new(paths: [feature_review_path(app1: 'abc', app2: 'def')])
      }
      let(:tickets) { [ticket1, ticket2] }

      it 'returns a unique collection of feature reviews' do
        expect(factory.create_from_tickets(tickets)).to match_array([
          FeatureReview.new(
            path: feature_review_path(app1: 'abc', app2: 'def'),
            versions: %w(abc def),
          ),
          FeatureReview.new(
            path: feature_review_path(app1: 'abc'),
            versions: %w(abc),
          ),
        ])
      end
    end
  end

  describe '#create_from_apps' do
    it 'returns a feature review for this version on a specific app' do
      apps = { 'abc' => 'apple' }

      feature_review = factory.create_from_apps(apps)
      expect(feature_review.versions).to eq(%w(apple))
      expect(feature_review.path).to eq('/feature_reviews?apps%5Babc%5D=apple')
    end
  end

  private

  def full_url(query_values)
    Addressable::URI.new(
      scheme: 'http',
      host:   'localhost',
      path:   '/feature_reviews',
      query_values: query_values,
    ).to_s
  end
end
