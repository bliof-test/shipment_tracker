class AddIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index(:builds, :version)
    add_index(:deploys, [:server, :app_name])
    add_index(:feature_reviews, :versions, using: 'gin')
    add_index(:manual_tests, :versions, using: 'gin')
    add_index(:tickets, :urls, using: 'gin')
    add_index(:uatests, :versions, using: 'gin')
  end
end
