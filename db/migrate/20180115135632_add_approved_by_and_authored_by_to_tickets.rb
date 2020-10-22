class AddApprovedByAndAuthoredByToTickets < ActiveRecord::Migration[4.2]
  def change
    add_column :tickets, :approved_by, :string
    add_column :tickets, :authored_by, :string
  end
end
