class RenameRepositoryLocationsToGitRepositoryLocations < ActiveRecord::Migration[4.2]
  def change
    rename_table :repository_locations, :git_repository_locations
  end
end
