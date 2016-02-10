class AddRegionToDeploys < ActiveRecord::Migration
  def change
    add_column :deploys, :region, :string
  end
end
