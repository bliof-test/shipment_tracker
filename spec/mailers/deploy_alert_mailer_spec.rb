# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeployAlertMailer do
  describe '#deploy_alert_email' do
    let(:mail) {
      described_class.deploy_alert_email(
        repo_owners: repo_owners,
        repo: 'awesome_app',
        region: 'gb',
        deployer: deployer,
        deployed_at: Time.new(2019, 2, 19, 16, 29, 0, '+00:00'),
        alert: '',
        releases_url: ''
      ).deliver_now
    }

    let(:repo_owners) {
      [
        FactoryBot.build(:repo_admin, email: 'important.person1@test.com'),
        FactoryBot.build(:repo_admin, email: 'important.person2@test.com'),
      ]
    }
    let(:deployer) { 'Foo Bar <foo.bar@test.com>' }

    it 'sends the email to the owners and copies the deployer' do
      expect(mail.to).to include('important.person1@test.com', 'important.person2@test.com')
      expect(mail.cc).to eq(['foo.bar@test.com'])
    end

    it 'sets the correct subject' do
      expect(mail.subject).to eq('Deploy alert for awesome_app - 2019-02-19 16:29:00 +0000')
    end
  end
end
