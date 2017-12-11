class AddApprovedByEmailToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :approved_by_email, :string
  end
end
