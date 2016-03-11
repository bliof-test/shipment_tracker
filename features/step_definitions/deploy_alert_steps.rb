Then 'a deploy alert should be dispatched for' do |table|
  table.hashes.each do |row|
    app, time, deployer, version, msg = row.values_at('app_name', 'time', 'deployer', 'version', 'message')

    expect(SlackNotifier).to have_received(:send).with(
      "GB Deploy Alert for #{app} at #{time}.\n"\
      "#{deployer} deployed #{scenario_context.resolve_version(version)}, #{msg}.",
      'general',
    )
  end
end

Then 'a deploy alert should not be dispatched' do
  expect(SlackNotifier).to_not have_received(:send)
end
