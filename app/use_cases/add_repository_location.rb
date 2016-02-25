class AddRepositoryLocation
  include SolidUseCase

  steps :validate, :add_repo, :generate_tokens

  def validate(args)
    validation_form = args[:validation_form]

    if validation_form.valid?
      continue(args)
    else
      fail :invalid_uri, :errors => validation_form.errors.full_messages.to_sentence
    end
  end

  def add_repo(args)
    uri = args[:uri]
    git_repository_location = GitRepositoryLocation.new(uri: uri)
    if !git_repository_location.save
      fail :failed_adding_repo, :errors => git_repository_location.errors.full_messages.to_sentence
    end

    repo_name = git_repository_location.name
    args.merge!(repo_name: repo_name)
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

    if !tokens_created
      fail :failed_generating_token
    else
      continue(args)
    end
  end

end
