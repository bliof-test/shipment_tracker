When 'I search tickets with keywords "$query"' do |query|
  dashboard_page.search_for(query: query)
end

Then 'I should find the following ticket on the dashboard:' do |tickets_table|
  result_tickets = dashboard_page.results
  expect(result_tickets).to eq tickets_table.hashes
end
