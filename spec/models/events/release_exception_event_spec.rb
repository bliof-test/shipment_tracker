# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Events::ReleaseExceptionEvent do
  subject(:event) { described_class.new(details: details) }

  let(:apps) { [{ 'name' => 'frontend', 'version' => 'abc' }] }
  let(:email) { 'test@example.com' }
  let(:comment) { 'Critical! Must be released ASAP' }
  let(:status) { 'approved' }

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

  describe '#path' do
    it 'returns the path' do
      expect(event.path).to eq '/feature_reviews?apps%5Bfrontend%5D=abc'
    end
  end

  describe '#comment' do
    it 'returns the comment' do
      expect(event.email).to eq(email)
    end

    context 'when there is no comment' do
      let(:details) { default_details.except('comment') }

      it 'returns an empty string' do
        expect(event.comment).to eq('')
      end
    end
  end

  describe '#approved?' do
    it 'returns the status' do
      expect(event.approved?).to be true
    end

    context 'when there is no status' do
      let(:details) { default_details.except('status') }

      it 'returns nil' do
        expect(event.approved?).to be false
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

  describe 'validation' do
    context 'when the owner owns at least 1 of the repos' do
      it 'creates an exception' do
        repo = create(:git_repository_location, name: 'frontend')
        owner = create(:repo_admin, email: 'test@example.com')

        expect_any_instance_of(Repositories::RepoOwnershipRepository)
          .to receive(:owners_of).with(repo).and_return([owner])

        event = build(
          :release_exception_event,
          apps: [%w(frontend abc)],
          email: 'test@example.com',
        )

        expect(event).to be_valid
      end
    end

    context 'when the owner does not own any of the repos' do
      it 'create an exception' do
        event = build(
          :release_exception_event,
          apps: [%w(frontend abc)],
          email: 'test2@example.com',
        )

        expect(event).not_to be_valid
      end
    end
  end
end
