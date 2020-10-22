class AddIndexToDeployAppName < ActiveRecord::Migration[4.2]
  def change
    add_index :deploys, :app_name
  end
end
