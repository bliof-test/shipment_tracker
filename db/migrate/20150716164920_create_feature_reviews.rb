class CreateFeatureReviews < ActiveRecord::Migration[4.2]
  def change
    create_table :feature_reviews do |t|
      t.string :url, unique: true
      t.string :versions, array: true
    end
    create_table :event_counts do |t|
      t.string :snapshot_name
      t.integer :event_id
    end
  end
end
