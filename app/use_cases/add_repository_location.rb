class AddRepositoryLocation
  include SolidUseCase

  steps :validate, :add_repo, :generate_tokens

  def validate(args)
    validation_form = args[:validation_form]

    if validation_form.valid?
      continue(args)
    else
      fail :invalid_uri
    end
  end

  def add_repo(args)
    uri = args[:uri]
    git_repository_location = GitRepositoryLocation.new(uri: uri)

    if git_repository_location.save
      continue(args)
    else
      fail :failed_adding_repo 
    end
  end

  def generate_tokens(args)
    continue(args)
  end

end
