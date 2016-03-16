class VersionResolver
  def initialize(git_repository)
    @git_repository = git_repository
  end

  def related_versions(version)
    return [] unless git_repository.exists?(version)
    resolved_version = resolve(version)
    [resolved_version] + child_versions(resolved_version)
  end

  private

  attr_reader :git_repository

  def resolve(version)
    return version unless git_repository.merge?(version)
    git_repository.branch_parent(version)
  end

  def child_versions(version)
    git_repository.get_descendant_commits_of_branch(version).map(&:id)
  end
end
