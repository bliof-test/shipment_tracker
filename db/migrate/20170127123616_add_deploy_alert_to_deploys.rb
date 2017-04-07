class AddDeployAlertToDeploys < ActiveRecord::Migration
  def change
    add_column :deploys, :deploy_alert, :string
    add_index :deploys, :deploy_alert
  end
end
