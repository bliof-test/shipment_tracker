# frozen_string_literal: true
Given 'I am on the new repository location form' do
  git_repository_location_page.visit
end

When 'I enter a valid uri "$uri"' do |uri|
  git_repository_location_page.fill_in(uri: uri)
end

Then 'I should see the repository locations:' do |table|
  expected_git_repository_locations = table.hashes.map { |row|
    expand_uri = row['URI'].strip.match(/uri_for\("(.*)"\)/)

    if expand_uri
      row['URI'] = scenario_context.repository_location_for(expand_uri[1]).uri
    end

    row
  }
  expect(git_repository_location_page.git_repository_locations).to eq(expected_git_repository_locations)
end

When 'I visit the tokens page' do
  tokens_page.visit
end

Given '"$application" repository' do |application|
  scenario_context.setup_application(application)
end

Given 'I am on the edit repository location form for "$application"' do |application|
  repo = scenario_context.repository_location_for(application)
  edit_git_repository_location_page.visit(repo)
end

Given 'owner of "$application" is "$owner"' do |application, owner|
  repo = scenario_context.repository_location_for(application)
  scenario_context.add_owners_to(repo, owners: owner)
end

When 'I enter owner emails "$repo_owners"' do |repo_owners|
  edit_git_repository_location_page.fill_in_repo_owners(repo_owners: repo_owners)
end

When 'I click "$button"' do |button|
  edit_git_repository_location_page.click(button)
end
