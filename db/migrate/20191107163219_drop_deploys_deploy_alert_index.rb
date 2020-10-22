class DropDeploysDeployAlertIndex < ActiveRecord::Migration[4.2]
  def up
    remove_index :deploys, :deploy_alert
  end

  def down
    add_index :deploys, :deploy_alert
  end
end
