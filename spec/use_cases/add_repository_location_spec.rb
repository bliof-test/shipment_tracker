require 'rails_helper'
require 'add_repository_location'
require 'forms/repository_locations_form'

RSpec.describe AddRepositoryLocation do
  let(:form) { double() }
  let(:git_repo_location) { double() }

  before do
    allow(form).to receive(:valid?).and_return(true)
  end

  context 'when valid URI and a token selected' do
    let(:token_types) { ['system_1', 'system2'] }
    let(:token_mock) { instance_double(Token) }

    before do
      allow(GitRepositoryLocation).to receive(:new).and_return(git_repo_location)
      allow(git_repo_location).to receive(:name).and_return('repo')
      allow(git_repo_location).to receive(:save).and_return(true)
      allow(token_mock).to receive(:save).and_return(true)
    end

    it 'runs successfully' do
      result = AddRepositoryLocation.run(validation_form: form, uri: 'git@github.com/owner/repo.git')
      expect(result).to be_a_success
    end

    it 'adds repository' do
      expect(GitRepositoryLocation).to receive(:new).and_return(git_repo_location)
      AddRepositoryLocation.run(validation_form: form, uri: 'git@github.com/owner/repo.git')
    end

    it 'generates token for each toke_type' do
      expect(Token).to receive(:new).exactly(token_types.size).times.and_return(token_mock)
      AddRepositoryLocation.run(
        validation_form: form,
        uri: 'git@github.com/owner/repo.git',
        token_types: token_types)
    end

    it 'generates token for each toke_type using repo name' do
      allow(GitRepositoryLocation).to receive(:new).and_return(git_repo_location)
      expect(Token).to receive(:new).with(
        name: 'repo',
        source: anything()
      ).exactly(token_types.size).times.and_return(token_mock)
      AddRepositoryLocation.run(
        validation_form: form,
        uri: 'git@github.com/owner/repo.git',
        token_types: token_types)
    end

    context 'token can not be saved' do
      before do
        allow(token_mock).to receive(:save).and_return(false)
        allow(Token).to receive(:new).and_return(token_mock)
      end

      it 'fails with token generation error' do
        allow(form).to receive(:valid?).and_return(true)
        result = AddRepositoryLocation.run(
          validation_form: form,
          uri: 'owner/repo.git',
          token_types: token_types
        )
        expect(result).to fail_with(:failed_generating_token)
      end
    end
  end

  context 'when invalid URI' do

    it 'fails validation' do
      allow(form).to receive(:valid?).and_return(false)
      result = AddRepositoryLocation.run(validation_form: form, uri: 'owner/repo.git')
      expect(result).to fail_with(:invalid_uri)
    end
  end
end
