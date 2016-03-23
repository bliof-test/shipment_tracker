# frozen_string_literal: true
Then 'a deploy alert should be dispatched for' do |table|
  table.hashes.each do |row|
    app, time, deployer, version, msg = row.values_at('app_name', 'time', 'deployer', 'version', 'message')

    expect(SlackClient).to have_received(:send_deploy_alert).with(
      "GB Deploy Alert for #{app} at #{time}.\n"\
      "#{deployer} deployed #{scenario_context.resolve_version(version)}.\n#{msg}",
      'https://localhost/releases/frontend?region=gb',
      app,
      deployer,
    )
  end
end

Then 'a deploy alert should not be dispatched' do
  expect(SlackClient).to_not have_received(:send_deploy_alert)
end
