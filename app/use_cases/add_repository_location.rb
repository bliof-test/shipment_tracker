# frozen_string_literal: true

require 'forms/repository_locations_form'

class AddRepositoryLocation
  include SolidUseCase

  steps :validate, :add_repo, :generate_tokens

  def validate(args)
    validation_form = Forms::RepositoryLocationsForm.new(args[:uri])

    return fail :invalid_uri, message: errors_for(validation_form) unless validation_form.valid?
    continue(args)
  end

  def add_repo(args)
    git_repo_location = GitRepositoryLocation.new(uri: args[:uri])

    return fail :failed_repo, message: errors_for(git_repo_location) unless git_repo_location.save

    repo_name = git_repo_location.name
    args[:repo_name] = repo_name
    continue(args)
  end

  def generate_tokens(args)
    token_types = args[:token_types]
    repo_name = args[:repo_name]
    return continue(repo_name) if token_types.nil?

    token_types.each do |token_type|
      token = Token.new(name: repo_name, source: token_type)
      return fail :failed_generating_token unless token.save
    end

    continue(repo_name)
  end

  private

  def errors_for(obj)
    obj.errors.full_messages.to_sentence
  end
end
