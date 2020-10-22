class AddIndexForPathToFeatureReviews < ActiveRecord::Migration[4.2]
  def change
    add_index :feature_reviews, :path
  end
end
