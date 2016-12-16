# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EmailValidator do
  class SampleRecord
    include ActiveModel::Model

    attr_accessor :email

    validates :email, email: true
  end

  describe '.valid?' do
    describe 'valid email adresses' do
      [
        'valid@dantooine.com',
        'Valid@test.dantooine.com',
        'valid+valid123@test.dantooine.com',
        'vaLid_valid123@test.dantooine.com',
        'valid-valid+123@test.dantooine.co.uk',
        'valid-valid+1.23@test.dantooine.com.au',
        'valid@dantooine.co.uk',
        'v@dantooine.com',
        'valid@dantooine.ca',
        'valid_@dantooine.com',
        'valid123.456@dantooine.org',
        'valid123.456@dantooine.travel',
        'valid123.456@dantooine.museum',
        'valid@dantooine.mobi',
        'valid@dantooine.info',
        'valid-@dantooine.com',
        'fake@p-t.k12.ok.us',
      ].each do |email|
        specify email do
          expect(SampleRecord.new(email: email).valid?).to eq(true)
        end
      end
    end

    describe 'invalid email addresses' do
      [
        'no_at_symbol',
        'invalid@dantooine-com',
        'invalid@ex_mple.com',
        'invalid@e..dantooine.com',
        'invalid@p-t..dantooine.com',
        'invalid@dantooine.com.',
        'invalid@dantooine.com_',
        'invalid@dantooine.com-',
        'invalid-dantooine.com',
        'invalid@dantooine.b#r.com',
        'invalid@dantooine.c',
        'invali d@dantooine.com',
        'invalid@dantooine.123',
        "valid@dantooine.com\n",
        "\nvalid@dantooine.com",
        ' valid@dantooine.com',
        'valid@dantooine.com ',
        "valid@dantooine.com\nvalid@dantooine.com",
        "valid@dantooine.com\nninja",
        "ninja\nvalid@dantooine.com",
      ].each do |email|
        specify email.inspect do
          expect(SampleRecord.new(email: email).valid?).to eq(false)
        end
      end
    end
  end
end
