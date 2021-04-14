class AddEventCreatedAtToFeatureReviews < ActiveRecord::Migration[4.2]
  def change
    add_column :feature_reviews, :event_created_at, :datetime
  end
end
