When 'I search tickets with keywords "$query"' do |query|
  dashboard_page.search_for(query: query)
end

Then 'I should find the following tickets on the dashboard:' do |tickets_table|
  result_tickets = dashboard_page.results
  hashes = tickets_table.hashes

  hashes.each do |hash|
    hash['Deploys'] = [hash['Deploys']]
  end

  expect(result_tickets).to eq hashes
end
