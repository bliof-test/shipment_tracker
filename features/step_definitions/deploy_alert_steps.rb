Then 'a deploy alert should be dispatched' do
  expect(SlackNotifier).to have_received(:send)
    .with(
      "GB Deploy Alert for frontend at 2016-01-22 17:34+00:00.\n"\
      "Jeff deployed #{scenario_context.resolve_version('#merge1')}, release not authorised.",
      'general',
    )
end
