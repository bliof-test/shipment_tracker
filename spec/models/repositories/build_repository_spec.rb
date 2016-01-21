require 'rails_helper'

RSpec.describe Repositories::BuildRepository do
  subject(:repository) { Repositories::BuildRepository.new }

  describe '#table_name' do
    let(:active_record_class) { class_double(Snapshots::Build, table_name: 'the_table_name') }

    subject(:repository) { Repositories::BuildRepository.new(active_record_class) }

    it 'delegates to the active record class backing the repository' do
      expect(repository.table_name).to eq('the_table_name')
    end
  end

  describe '#builds_for' do
    let(:apps) { { 'frontend' => 'abc' } }

    it 'projects last build' do
      repository.apply(build(:jenkins_event, success?: false, version: 'abc'))
      expect(repository.builds_for(apps: apps)).to eq(
        'frontend' => Build.new(source: 'Jenkins', success: false, version: 'abc'),
      )

      repository.apply(build(:jenkins_event, success?: true, version: 'abc'))
      expect(repository.builds_for(apps: apps)).to eq(
        'frontend' => Build.new(source: 'Jenkins', success: true, version: 'abc'),
      )
    end

    context 'with multiple apps' do
      let(:apps) { { 'frontend' => 'abc', 'backend' => 'def', 'other' => 'xyz' } }

      it 'returns multiple builds' do
        repository.apply(build(:jenkins_event, success?: false, version: 'abc'))
        repository.apply(build(:circle_ci_event, success?: true, version: 'def'))

        expect(repository.builds_for(apps: apps)).to eq(
          'frontend' => Build.new(source: 'Jenkins', success: false, version: 'abc'),
          'backend'  => Build.new(source: 'CircleCi', success: true, version: 'def'),
          'other'    => Build.new,
        )
      end
    end

    context 'with at specified' do
      it 'returns the state at that moment' do
        repository.apply(build(:circle_ci_event, success?: true, version: 'abc', created_at: 3.hours.ago))
        repository.apply(build(:circle_ci_event, success?: true, version: 'def', created_at: 2.hours.ago))
        repository.apply(build(:circle_ci_event, success?: false, version: 'abc', created_at: 1.hour.ago))
        repository.apply(build(:circle_ci_event, success?: false, version: 'def', created_at: Time.current))

        result = repository.builds_for(
          apps: {
            'app1' => 'abc',
            'app2' => 'def',
          },
          at: 2.hours.ago,
        )

        expect(result).to eq(
          'app1' => Build.new(source: 'CircleCi', success: true, version: 'abc'),
          'app2' => Build.new(source: 'CircleCi', success: true, version: 'def'),
        )
      end
    end
  end
end
