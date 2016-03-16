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
        expect(build(:jira_event, :rejected).approval?).to be false
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
        expect(build(:jira_event, :rejected).unapproval?).to be true
      end
    end
  end
end
