Given 'I am on the new repository location form' do
  git_repository_location_page.visit
end

When 'I enter a valid uri "$uri"' do |uri|
  git_repository_location_page.fill_in(uri: uri)
end

Then 'I should see the repository locations:' do |table|
  expected_git_repository_locations = table.hashes
  expect(git_repository_location_page.git_repository_locations).to eq(expected_git_repository_locations)
end

And 'I select the tokens for auto-generation:' do |table|
  token_types = table.hashes.map{ |row| row['Tokens'] }
  token_types.each do |token_type|
    git_repository_location_page.check_token_type(token_type)
  end
end
