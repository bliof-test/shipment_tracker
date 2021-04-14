class AddApprovedAtToFeatureReviews < ActiveRecord::Migration[4.2]
  def change
    add_column :feature_reviews, :approved_at, :datetime
  end
end
