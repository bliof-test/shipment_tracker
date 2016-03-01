require 'jira'

class JiraClient
  def self.post_comment(issue_id, comment_msg)
    issue = get_issue(issue_id)
    comment = issue.comments.build
    comment.save('body': comment_msg)
  end

  def self.get_issue(id)
    jira_client.client.Issue.find(id)
  end
  private_class_method :get_issue

  def self.jira_client
    @options ||= {
      username: ShipmentTracker::JIRA_USER,
      password: ShipmentTracker::JIRA_PASSWD,
      site: ShipmentTracker::JIRA_HOST_NAME,
      context_path: ShipmentTracker::JIRA_PATH,
      auth_type: :basic,
      read_timeout: 120,
    }

    @jira_client ||= JIRA::Client.new(options)
  end
  private_class_method :jira_client
end
