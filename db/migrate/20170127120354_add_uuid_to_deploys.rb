class AddUuidToDeploys < ActiveRecord::Migration
  def change
    add_column :deploys, :uuid, :uuid
    add_index :deploys, :uuid, unique: true
  end
end
