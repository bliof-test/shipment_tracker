class RenameFeatureReviewUrlToPath < ActiveRecord::Migration[4.2]
  def change
    rename_column :feature_reviews, :url, :path
  end
end
