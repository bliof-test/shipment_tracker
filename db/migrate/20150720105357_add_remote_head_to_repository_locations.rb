class AddRemoteHeadToRepositoryLocations < ActiveRecord::Migration[4.2]
  def change
    add_column :repository_locations, :remote_head, :string
  end
end
