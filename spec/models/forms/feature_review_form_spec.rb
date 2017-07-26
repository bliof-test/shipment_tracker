# frozen_string_literal: true
require 'spec_helper'
require 'forms/feature_review_form'

RSpec.describe Forms::FeatureReviewForm do
  let(:git_repository_loader) { instance_double(GitRepositoryLoader) }
  let(:apps) { {} }

  def feature_review_form_for(apps)
    described_class.new(apps: apps, git_repository_loader: git_repository_loader)
  end

  subject(:feature_review_form) { feature_review_form_for(apps) }

  describe '.new' do
    context 'with a git_repository_loader' do
      it 'should work' do
        expect(described_class.new(apps: {}, git_repository_loader: double))
          .to be_a(described_class)
      end
    end

    context 'without a git_repository_loader' do
      it 'should work' do
        expect(described_class.new(apps: {})).to be_a(described_class)
      end
    end
  end

  describe '#apps' do
    context 'when there are no app versions' do
      let(:apps) { nil }
      it 'return an empty hash' do
        expect(feature_review_form.apps).to eql({})
      end
    end

    context 'when there are no app versions' do
      let(:apps) { { 'app1' => 'a', 'app2' => 'b', 'app3' => '' } }
      it 'returns the apps with empty ones filtered out' do
        expect(feature_review_form.apps).to eql('app1' => 'a', 'app2' => 'b')
      end
    end
  end

  describe '#valid?' do
    context 'when any of the app versions are invalid' do
      let(:invalid_sha) { 'd3adb33f' }
      let(:apps) { { frontend: invalid_sha, backend: 'abc' } }
      let(:frontend_repo) { instance_double(GitRepository) }
      let(:backend_repo) { instance_double(GitRepository) }

      before do
        allow(git_repository_loader).to receive(:load).with('frontend').and_return(frontend_repo)
        allow(git_repository_loader).to receive(:load).with('backend').and_return(backend_repo)

        allow(frontend_repo).to receive(:exists?).with(invalid_sha).and_return(false)
        allow(backend_repo).to receive(:exists?).with('abc').and_return(true)
      end

      it 'returns false' do
        expect(feature_review_form.valid?).to be false
      end

      it 'adds errors' do
        feature_review_form.valid?
        expect(feature_review_form.errors[:frontend]).to eq(["#{invalid_sha} does not exist or is too short"])
        expect(feature_review_form.errors[:backend]).to be_empty
      end
    end

    context 'when an app does not exist' do
      let(:apps) { { frontend: 'abc' } }
      let(:frontend_repo) { instance_double(GitRepository) }

      before do
        allow(git_repository_loader).to receive(:load)
          .with('frontend')
          .and_raise(GitRepositoryLoader::NotFound)
      end

      it 'returns false' do
        expect(feature_review_form.valid?).to be false
      end

      it 'adds errors' do
        feature_review_form.valid?
        expect(feature_review_form.errors[:frontend]).to eq(['does not exist'])
      end
    end

    context 'when all the app versions exist' do
      let(:apps) { { frontend: 'abc', backend: 'def' } }
      let(:frontend_repo) { instance_double(GitRepository) }
      let(:backend_repo) { instance_double(GitRepository) }

      before do
        allow(git_repository_loader).to receive(:load).with('frontend').and_return(frontend_repo)
        allow(git_repository_loader).to receive(:load).with('backend').and_return(backend_repo)

        allow(frontend_repo).to receive(:exists?).with('abc').and_return(true)
        allow(backend_repo).to receive(:exists?).with('def').and_return(true)
      end

      it 'returns true' do
        expect(feature_review_form.valid?).to be true
      end

      it 'does not add errors' do
        feature_review_form.valid?
        expect(feature_review_form.errors).to be_empty
      end
    end

    context 'when an app version is not filled in' do
      let(:apps) { { frontend: 'abc', backend: '' } }
      let(:frontend_repo) { instance_double(GitRepository) }

      before do
        allow(git_repository_loader).to receive(:load).with('frontend').and_return(frontend_repo)
        allow(frontend_repo).to receive(:exists?).with('abc').and_return(true)
      end

      it 'returns true' do
        expect(feature_review_form.valid?).to be true
      end
    end

    context 'when no apps are specified' do
      let(:apps) { {} }

      it 'returns true' do
        expect(feature_review_form.valid?).to be false
      end
    end
  end

  describe '#path' do
    it 'will not include apps without versions' do
      expect(feature_review_form_for(frontend: 'abc', backend: '').path)
        .to eq('/feature_reviews?apps%5Bfrontend%5D=abc')
    end

    it 'orders apps alphabetically' do
      form = feature_review_form_for(a: 1, c: 3, b: 2, e: 5, d: 4)

      expect(form.path).to eq(
        '/feature_reviews?'\
        'apps%5Ba%5D=1&'\
        'apps%5Bb%5D=2&'\
        'apps%5Bc%5D=3&'\
        'apps%5Bd%5D=4&'\
        'apps%5Be%5D=5',
      )
    end
  end
end
