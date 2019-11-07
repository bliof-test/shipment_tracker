class DropDeploysDeployAlertIndex < ActiveRecord::Migration
  def up
    remove_index :deploys, :deploy_alert
  end

  def down
    add_index :deploys, :deploy_alert
  end
end
