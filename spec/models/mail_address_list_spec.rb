# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MailAddressList do
  describe '.new' do
    it 'is an empty address list by default' do
      expect(described_class.new.addresses).to be_empty
    end

    it 'is an empty address list when nil is provided' do
      expect(described_class.new(nil).addresses).to be_empty
    end

    it 'can be created with a string' do
      expect(described_class.new('test@test.com, test2@test.com').format)
        .to eq('test@test.com, test2@test.com')
    end

    it 'can be created by and array of hashes' do
      expect(
        described_class.new([
          { name: 'Test', email: 'test@test.com' },
          { email: 'test2@test.com' },
        ]).format,
      ).to eq('Test <test@test.com>, test2@test.com')
    end
  end

  describe '#valid?' do
    it 'is true when it can parse the list of emails' do
      expect(described_class.new('')).to be_valid
      expect(described_class.new('test@test.com')).to be_valid
      expect(described_class.new('test@test.com, test2@test.com')).to be_valid
      expect(described_class.new('<test@test.com>')).to be_valid
      expect(described_class.new('Test <test@test.com>')).to be_valid
      expect(
        described_class.new(
          [
            'Test <test@test.com>',
            'test2@test.com',
          ].join(', '),
        ),
      ).to be_valid
    end

    it 'is false when there is an the emails are invalid' do
      expect(described_class.new('test.com')).not_to be_valid
      expect(described_class.new('test@test@test.com')).not_to be_valid
      expect(described_class.new('test@test')).not_to be_valid
      expect(described_class.new('test@test, test@test.com')).not_to be_valid
    end
  end

  describe '#format' do
    it 'empty address list is formatted as an empty string' do
      expect(described_class.new('').format).to eq('')
    end

    it 'formats the emails and stripts all unneeded spaces' do
      expect(
        described_class.new(
          [
            '      Test<test@test.com>    ',
            'Test2        <test2@test.com>',
            '  test2@test.com    ',
            '<test2@test.com>',
          ].join(', '),
        ).format,
      ).to eq(
        [
          'Test <test@test.com>',
          'Test2 <test2@test.com>',
          'test2@test.com',
          'test2@test.com',
        ].join(', '),
      )
    end

    context 'with keep_brackets true' do
      it 'will keep the brackets around emails without display_name' do
        expect(
          described_class.new(
            [
              '      Test<test@test.com>    ',
              'Test2        <test2@test.com>',
              '  test2@test.com    ',
              '<test2@test.com>',
            ].join(', '),
          ).format(keep_brackets: true),
        ).to eq(
          [
            'Test <test@test.com>',
            'Test2 <test2@test.com>',
            'test2@test.com',
            '<test2@test.com>',
          ].join(', '),
        )
      end
    end
  end

  describe '#addresses' do
    it 'returns an array of Mail::Address' do
      addresses = described_class.new('<test@test.com>').addresses

      expect(addresses.size).to eq(1)
      expect(addresses.first).to be_a(Mail::Address)
    end

    it 'is empty array when there are no addresses' do
      expect(described_class.new('').addresses).to eq([])
    end
  end

  describe '#each' do
    it 'iterates over the addresses' do
      address_list = described_class.new('test@test.com, test2@test.com')

      iterated_emails = []

      address_list.each { |email| iterated_emails << email }

      expect(iterated_emails).to eq(address_list.addresses)
    end
  end

  describe '#include?' do
    it 'is true when the email is in the address list' do
      expect(described_class.new('test@test.com')).to include('test@test.com')
      expect(described_class.new('test@test.com, test2@test.com')).to include('test2@test.com')
      expect(described_class.new('<test@test.com>')).to include('test@test.com')
      expect(described_class.new('Test <test@test.com>')).to include('test@test.com')
    end
  end
end
