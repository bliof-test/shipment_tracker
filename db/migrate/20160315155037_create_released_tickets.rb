class CreateReleasedTickets < ActiveRecord::Migration
  def change
    create_table :released_tickets do |t|
      t.string :key
      t.string :summary
      t.text :description
      t.timestamps null: false
    end
  end
end
