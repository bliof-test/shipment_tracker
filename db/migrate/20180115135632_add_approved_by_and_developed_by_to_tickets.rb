class AddApprovedByAndDevelopedByToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :approved_by, :string
    add_column :tickets, :developed_by, :string
  end
end
