class CreateReleasedTickets < ActiveRecord::Migration
  def change
    create_table :released_tickets do |t|
      t.string :key
      # TODO: summary can be string
      t.string :summary
      t.text :description
    end
  end
end
