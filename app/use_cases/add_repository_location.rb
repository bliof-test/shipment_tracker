class AddRepositoryLocation
  include SolidUseCase

  steps :validate, :add_repo, :generate_tokens

  def validate(args)
    validation_form = args[:validation_form]

    return fail :invalid_uri, message: get_errors_msg(validation_form) unless validation_form.valid?
    continue(args)
  end

  def add_repo(args)
    uri = args[:uri]
    git_repo_location = GitRepositoryLocation.new(uri: uri)

    return fail :failed_repo, message: get_errors_msg(git_repo_location) unless git_repo_location.save

    repo_name = git_repo_location.name
    args[:repo_name] = repo_name
    continue(args)
  end

  def generate_tokens(args)
    token_types = args[:token_types]
    repo_name = args[:repo_name]
    return continue(repo_name) if token_types.nil?

    tokens_created = true
    token_types.each do |token_type|
      token = Token.new(name: repo_name, source: token_type)
      tokens_created &= token.save
    end

    return fail :failed_generating_token unless tokens_created
    continue(repo_name)
  end

  private

  def get_errors_msg(obj)
    obj.errors.full_messages.to_sentence
  end
end
