# frozen_string_literal: true
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

When 'I visit the tokens page' do
  tokens_page.visit
end
