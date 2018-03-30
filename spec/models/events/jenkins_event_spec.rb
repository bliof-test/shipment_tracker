# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_examples/test_build_examples'

RSpec.describe Events::JenkinsEvent do
  it_behaves_like 'a test build interface'
  it_behaves_like 'a test build subclass' do
    subject { described_class.new(details: payload) }
    let(:expected_source) { 'Jenkins' }

    let(:version) { '123' }
    let(:payload) { success_payload }
    let(:success_payload) {
      {
        'build' => {
          'app_name' => 'example',
          'build_type' => 'integration',
          'full_url' => 'http://example.com',
          'scm' => {
            'commit' => version,
          },
          'status' => 'SUCCESS',
        },
      }
    }
    let(:failure_payload) {
      {
        'build' => {
          'app_name' => 'example',
          'build_type' => 'integration',
          'full_url' => 'http://example.com',
          'scm' => {
            'commit' => version,
          },
          'status' => 'FAILURE',
        },
      }
    }
    let(:invalid_payload) {
      { some: 'nonsense' }
    }
  end
end
