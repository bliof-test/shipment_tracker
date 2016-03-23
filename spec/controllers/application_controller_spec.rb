# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ApplicationController, :logged_in do
  controller do
    def index
      head 200
    end
  end

  describe '#data_maintenance_warning' do
    context 'when application is in maintenance mode' do
      before do
        allow(Rails.configuration).to receive(:data_maintenance_mode).and_return(true)
      end

      context 'when the request format is html' do
        it 'shows a flash warning message' do
          get :index
          expect(flash[:warning]).to eq('The site is currently undergoing maintenance. '\
                                        'Some data may appear out-of-date. ¯\\_(ツ)_/¯')
        end
      end

      context 'when the request format is not html' do
        it 'does not show a flash warning message' do
          get :index, format: 'json'
          expect(flash[:warning]).to be nil
        end
      end
    end

    context 'when application is not in maintenance mode' do
      before do
        allow(Rails.configuration).to receive(:data_maintenance_mode).and_return(false)
      end

      it 'does not show a flash warning message' do
        get :index
        expect(flash[:warning]).to be nil
      end
    end
  end

  describe '#path_from_url' do
    subject(:path_from_url) { ApplicationController.new.path_from_url(argument) }

    context 'when URL is given' do
      let(:argument) { 'http://example.com/with-path?some=param' }
      it 'returns the path' do
        expect(path_from_url).to eq('/with-path?some=param')
      end
    end

    context 'when PATH is given' do
      let(:argument) { '/just-path?some=param' }

      it 'returns the path' do
        expect(path_from_url).to eq('/just-path?some=param')
      end
    end

    context 'when called with unparseable string' do
      let(:argument) { 'any old string' }
      it 'returns nil' do
        expect(path_from_url).to be_nil
      end
    end

    context 'when called with nil' do
      let(:argument) { nil }
      it 'returns nil' do
        expect(path_from_url).to be_nil
      end
    end
  end
end
