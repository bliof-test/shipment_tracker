class RenameEventCreatedAtToDeployedAt < ActiveRecord::Migration[4.2]
  def change
    rename_column :deploys, :event_created_at, :deployed_at
  end
end
