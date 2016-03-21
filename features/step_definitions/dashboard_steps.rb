When 'I search tickets with keywords "$query"' do |query|
  dashboard_page.search_for(query: query)
end

Then 'I should find the following tickets on the dashboard:' do |tickets_table|
  result_tickets = dashboard_page.results
  hashes = tickets_table.hashes

  hashes.each do |hash|
    hash['Deploys'] = hash['Deploys'].split(',').map { |deploy_string|
      deploy_string_without_version, pretend_version = deploy_string.split('#')

      real_version = scenario_context.resolve_version("##{pretend_version}")
      short_version = real_version.slice(0..6)

      (deploy_string_without_version + short_version).strip
    }
  end

  expect(result_tickets).to eq hashes
end
