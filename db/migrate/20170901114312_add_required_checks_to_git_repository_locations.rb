class AddRequiredChecksToGitRepositoryLocations < ActiveRecord::Migration
  def change
    add_column :git_repository_locations, :required_checks, :text, array: true, default: []
  end
end
