class AddApprovedByAndAuthoredByToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :approved_by, :string
    add_column :tickets, :authored_by, :string
  end
end
