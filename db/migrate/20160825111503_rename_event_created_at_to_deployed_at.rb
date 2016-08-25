class RenameEventCreatedAtToDeployedAt < ActiveRecord::Migration
  def change
    rename_column :deploys, :event_created_at, :deployed_at
  end
end
