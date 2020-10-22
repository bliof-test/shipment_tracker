class RenameRepositoriesToRepositoryLocations < ActiveRecord::Migration[4.2]
  def change
    rename_table :repositories, :repository_locations
  end
end
