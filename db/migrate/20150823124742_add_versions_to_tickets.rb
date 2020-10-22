class AddVersionsToTickets < ActiveRecord::Migration[4.2]
  def change
    add_column :tickets, :versions, :string, array: true
    add_index :tickets, :versions, using: 'gin'
    add_index :deploys, :version
  end
end
