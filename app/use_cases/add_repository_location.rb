class AddRepositoryLocation
  include SolidUseCase

  steps :validate, :add_repo, :generate_tokens

  def validate(args)
    validation_form = args[:validation_form]

    return fail :invalid_uri, errors: get_errors_msg(validation_form) unless validation_form.valid?
    continue(args)
  end

  def add_repo(args)
    uri = args[:uri]
    git_repository_location = GitRepositoryLocation.new(uri: uri)
    unless git_repository_location.save
      fail :failed_adding_repo, errors: get_errors_msg(git_repository_location)
    end

    repo_name = git_repository_location.name
    args[:repo_name] = repo_name
    continue(args)
  end

  def generate_tokens(args)
    token_types = args[:token_types]
    return continue(args) if token_types.nil?

    repo_name = args[:repo_name]

    tokens_created = true
    token_types.each do |token_type|
      token = Token.new(name: repo_name, source: token_type)
      tokens_created &= token.save
    end

    return fail :failed_generating_token unless tokens_created
    continue(args[:repo_name])
  end

  private

  def get_errors_msg(obj)
    obj.errors.full_messages.to_sentence
  end
end
