# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Events::JiraEvent do
  describe '#approval?' do
    context 'when the status changes from unapproved to approved' do
      it 'returns true' do
        expect(build(:jira_event, :approved).approval?).to be true
      end
    end

    context 'when the status changes from approved to approved' do
      it 'returns false' do
        expect(build(:jira_event, :deployed).approval?).to be false
      end
    end

    context 'when the status changes from unapproved to unapproved' do
      it 'returns false' do
        expect(build(:jira_event, :development_completed).approval?).to be false
      end
    end

    context 'when the status changes from approved to unapproved' do
      it 'returns false' do
        expect(build(:jira_event, :unapproved).approval?).to be false
      end
    end
  end

  describe '#unapproval?' do
    context 'when the status changes from unapproved to approved' do
      it 'returns false' do
        expect(build(:jira_event, :approved).unapproval?).to be false
      end
    end

    context 'when the status changes from approved to approved' do
      it 'returns false' do
        expect(build(:jira_event, :deployed).unapproval?).to be false
      end
    end

    context 'when the status changes from unapproved to unapproved' do
      it 'returns false' do
        expect(build(:jira_event, :development_completed).unapproval?).to be false
      end
    end

    context 'when the status changes from approved to unapproved' do
      it 'returns true' do
        expect(build(:jira_event, :unapproved).unapproval?).to be true
      end
    end
  end

  describe '#transfer?' do
    it 'returns true' do
      expect(build(:jira_event, :moved).transfer?).to be true
    end
  end

  describe '#development?' do
    it 'returns true' do
      expect(build(:jira_event, :started).development?).to be true
    end

    it 'returns false' do
      expect(build(:jira_event, :approved).development?).to be false
    end
  end

  describe 'changelog_old_key' do
    it 'returns old key of a moved ticket' do
      expect(build(:jira_event, :moved).changelog_old_key).to eq 'ONEJIRA-1'
    end

    it 'return of ticket that is not moved' do
      expect(build(:jira_event, :started).changelog_old_key).to be nil
    end
  end

  describe 'changelog_new_key' do
    it 'returns old key of a moved ticket' do
      expect(build(:jira_event, :moved).changelog_new_key).to eq 'TWOJIRA-2'
    end

    it 'return of ticket that is not moved' do
      expect(build(:jira_event, :started).changelog_new_key).to be nil
    end
  end

  describe '#user_email' do
    it 'returns the email of the user' do
      expect(build(:jira_event, :created).user_email).to eq 'joe.bloggs@example.com'
    end
  end

  describe '#assignee_email' do
    it 'returns the email of the assignee' do
      expect(build(:jira_event, :development_completed).assignee_email).to eq 'joe.assignee@example.com'
    end
  end
end
