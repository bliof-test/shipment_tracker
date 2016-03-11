class AddIndexToDeployAppName < ActiveRecord::Migration
  def change
    add_index :deploys, :app_name
  end
end
