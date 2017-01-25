class CreateRepoOwnersAndRepoOwnerships < ActiveRecord::Migration
  def change
    create_table :repo_owners do |t|
      t.string :name
      t.string :email, null: false
      t.timestamps null: false
    end

    add_index :repo_owners, :email, unique: true

    create_table :repo_ownerships do |t|
      t.string :app_name, null: false
      t.string :repo_owners
      t.timestamps null: false
    end

    add_index :repo_ownerships, :app_name, unique: true
  end
end
