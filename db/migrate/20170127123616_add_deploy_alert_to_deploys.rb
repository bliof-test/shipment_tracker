class AddDeployAlertToDeploys < ActiveRecord::Migration[4.2]
  def change
    add_column :deploys, :deploy_alert, :string
    add_index :deploys, :deploy_alert
  end
end
