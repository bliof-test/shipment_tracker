# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TicketValidationHelper do
  class ClassWithTicketValidator
    include SolidUseCase
    include TicketValidationHelper

    def invalid_key_message(_args)
      'Not valid at all'
    end
  end

  let(:object) { ClassWithTicketValidator.new }

  describe '#validate_id_format' do
    context 'when jira key is valid' do
      let(:args) { { jira_key: 'NS-123' } }

      it 'continues' do
        expect(object).to receive(:continue).with(args)
        object.validate_id_format(args)
      end
    end

    context 'when jira key is invalid' do
      let(:args) { { jira_key: 'nope' } }

      specify {
        expect(object).to receive(:fail).with(:invalid_key, message: 'Not valid at all')
        object.validate_id_format(args)
      }
    end
  end
end
