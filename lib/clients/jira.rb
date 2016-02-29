require 'jira'

class JiraClient
  def self.post_comment(issue_id, comment_msg)
    issue = get_issue(issue_id)
    comment = issue.comments.build
    comment.save('body': comment_msg)
  end

  def self.get_issue(id)
    client = jira_client
    client.Issue.find(id)
  end
  private_class_method :get_issue

  def self.jira_client
    options = {
      username: ENV['JIRA_USER'],
      password: ENV['JIRA_PASSWD'],
      site: ENV['JIRA_HOST'],
      context_path: ENV['JIRA_PATH'],
      auth_type: :basic,
      read_timeout: 120,
    }

    @jira_client ||= JIRA::Client.new(options)
  end
  private_class_method :jira_client
end
