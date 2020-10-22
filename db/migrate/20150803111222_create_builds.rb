class CreateBuilds < ActiveRecord::Migration[4.2]
  def change
    create_table :builds do |t|
      t.string :version
      t.boolean :success
      t.string :source
      t.datetime :event_created_at
    end
  end
end
