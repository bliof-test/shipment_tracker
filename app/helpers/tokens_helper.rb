module TokensHelper
  def token_link(source:, token:)
    if source == 'github_notifications'
      github_notifications_url(token: token)
    else
      events_url(type: source, token: token)
    end
  end
end
