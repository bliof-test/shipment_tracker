class CreateUatest < ActiveRecord::Migration[4.2]
  def change
    create_table :uatests do |t|
      t.string :server
      t.boolean :success
      t.string :test_suite_version

      # Terrible thing to ensure we are now compatible with older version of Postgres
      # t.jsonb :versions
      t.json :versions

      t.datetime :event_created_at
    end
  end
end
