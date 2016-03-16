require 'rails_helper'

RSpec.describe Repositories::ManualTestRepository do
  subject(:repository) { Repositories::ManualTestRepository.new }

  describe '#table_name' do
    let(:active_record_class) { class_double(Snapshots::ManualTest, table_name: 'the_table_name') }

    subject(:repository) { Repositories::ManualTestRepository.new(active_record_class) }

    it 'delegates to the active record class backing the repository' do
      expect(repository.table_name).to eq('the_table_name')
    end
  end

  describe '#qa_submission_for' do
    it 'projects last QA submission' do
      # usec reset is required as the precision for the database column is not as great as the Time class,
      # without it, tests would fail on CI build.
      t = [4.hours.ago, 3.hours.ago, 2.hours.ago, 1.hour.ago].map { |time| time.change(usec: 0) }

      default = { apps: { 'app1' => '1', 'app2' => '2' }, email: 'foo@ex.io', comment: 'Good' }
      events = [
        build(:manual_test_event, default.merge(accepted: false, created_at: t[0])),
        build(:manual_test_event, default.merge(apps: { 'app2' => '2' }, accepted: false, created_at: t[1])),
        build(:manual_test_event, default.merge(accepted: true, created_at: t[2])),
        build(:manual_test_event, default.merge(apps: { 'app1' => '1' }, accepted: false, created_at: t[3])),
      ]

      events.each do |event|
        repository.apply(event)
      end

      result = repository.qa_submission_for(versions: %w(1 2))

      expect(result).to eq(
        QaSubmission.new(email: 'foo@ex.io', accepted: true, comment: 'Good', created_at: t[2]),
      )
    end

    context 'with at specified' do
      it 'returns the state at that moment' do
        default = { apps: { 'app1' => 'abc', 'app2' => 'def' }, email: 'foo@ex.io', comment: 'Good' }

        times = [3.hours.ago, 2.hours.ago, 1.hour.ago].map { |t| t.change(usec: 0) }
        events = [
          build(:manual_test_event, default.merge(accepted: false, created_at: times[0])),
          build(:manual_test_event, default.merge(accepted: true, created_at: times[1])),
          build(:manual_test_event, default.merge(accepted: false, created_at: times[2])),
        ]

        events.each do |event|
          repository.apply(event)
        end

        result = repository.qa_submission_for(versions: %w(abc def), at: 2.hours.ago)

        expect(result).to eq(
          QaSubmission.new(email: 'foo@ex.io', accepted: true, comment: 'Good', created_at: times[1]),
        )
      end
    end
  end
end
