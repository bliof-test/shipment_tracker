class CreateReleaseExceptions < ActiveRecord::Migration
  def change
    create_table :release_exceptions do |t|
      t.references :repo_owner, index: true, foreign_key: true
      t.text :versions, array: true, default: []
      t.boolean :approved
      t.text :comment
      t.datetime :submitted_at, null: false
      t.timestamps
    end

    add_index :release_exceptions, :submitted_at
  end
end
