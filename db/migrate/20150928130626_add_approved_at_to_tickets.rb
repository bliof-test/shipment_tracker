class AddApprovedAtToTickets < ActiveRecord::Migration[4.2]
  def change
    add_column :tickets, :approved_at, :datetime
  end
end
