class AddUuidToDeploys < ActiveRecord::Migration[4.2]
  def change
    add_column :deploys, :uuid, :uuid
    add_index :deploys, :uuid, unique: true
  end
end
