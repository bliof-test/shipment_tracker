require 'addressable/uri'

When 'I generate a token for "$source" with name "$name"' do |source, name|
  tokens_page.visit
  tokens_page.generate_token_for(source, name)
end

Then 'I should see the tokens' do |tokens_table|
  expected_tokens = tokens_table.hashes
  actual_tokens = tokens_page.tokens

  expected_tokens.zip(actual_tokens).each do |expected_token, actual_token|
    expect(actual_token['Name']).to eq(expected_token['Name'])
    expect(actual_token['Source']).to eq(expected_token['Source'])

    actual_token_url = Addressable::URI.parse(actual_token['URL'])
    expect(actual_token_url.scheme).to eq('http')
    expect(actual_token_url.host).to eq('www.example.com')
    expect(actual_token_url.path).to eq("/events/#{expected_token['Endpoint']}")
    expect(actual_token_url.query_values['token'].length).to eq(24)
  end
end

When 'I revoke it' do
  tokens_page.revoke_last_token
end

Then 'I should not see any tokens' do
  expect(tokens_page.tokens).to be_empty
end
