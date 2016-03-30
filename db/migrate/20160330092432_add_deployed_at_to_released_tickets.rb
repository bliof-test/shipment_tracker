class AddDeployedAtToReleasedTickets < ActiveRecord::Migration
  def change
    add_column :released_tickets, :first_deployed_at, :datetime
    add_column :released_tickets, :last_deployed_at, :datetime

    add_index :released_tickets, :first_deployed_at
    add_index :released_tickets, :last_deployed_at
  end
end
