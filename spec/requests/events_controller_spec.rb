# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'EventsController' do
  describe 'POST #create' do
    let(:event_factory) { instance_double(Factories::EventFactory) }

    before do
      allow(Factories::EventFactory).to receive(:from_rails_config).and_return(event_factory)
    end

    context 'with a cookie' do
      let(:user_email) { 'alice@fundingcircle.com' }

      before do
        login_with_omniauth(email: user_email)
      end

      it 'saves the event' do
        expect(event_factory).to receive(:create).with(
          'circleci',
          { 'foo' => 'bar' },
          user_email,
        )

        post '/events/circleci', foo: 'bar'

        expect(response).to be_ok
        expect(response.headers).to have_key('Set-Cookie')
      end

      context 'with a return_to param' do
        before do
          allow(event_factory).to receive(:create).with('circleci', {}, user_email)
        end

        context 'when return_to is a relative path' do
          it 'redirects to the path' do
            post '/events/circleci?return_to=/my/projection?with=data'

            expect(response).to redirect_to('/my/projection?with=data')
          end
        end

        context 'when return_to is an absolute path' do
          it 'ignores the domain and just redirects to the path' do
            post '/events/circleci?return_to=http://evil.com/magic/url?with=query'

            expect(response).to redirect_to('/magic/url?with=query')
          end
        end

        context 'when return_to is not a valid path' do
          it 'does not redirect' do
            post '/events/circleci?return_to=TOTALLY NOT VALID'

            expect(response).to_not have_http_status(302), 'We should not redirect'
          end
        end

        context 'when return_to is blank' do
          it 'does not redirect' do
            post '/events/circleci?return_to='

            expect(response).to_not have_http_status(302), 'We should not redirect'
          end
        end
      end
    end

    context 'with a valid token in the path' do
      let(:token) { 'abc123' }

      before do
        allow(Token).to receive(:valid?).and_return(false)
        allow(Token).to receive(:valid?).with('circleci', token).and_return(true)
      end

      it 'saves the event' do
        expect(event_factory).to receive(:create).with(
          'circleci', { 'foo' => 'bar', 'token' => 'the payloads token' }, nil
        )

        post "/events/circleci?token=#{token}", foo: 'bar', token: 'the payloads token'

        expect(response).to be_ok
      end

      it 'does not create authorised session' do
        expect(event_factory).to receive(:create).once

        post "/events/circleci?token=#{token}", foo: 'bar', token: 'the payloads token'

        # subsequent post without token should not work
        post '/events/circleci', more: 'data'
        expect(response).to be_forbidden
      end
    end

    context 'with no token' do
      it 'returns 403 Forbidden' do
        post '/events/circleci', foo: 'bar'

        expect(response).to be_forbidden
      end
    end

    context 'with an invalid token' do
      it 'returns 403 Forbidden' do
        post '/events/circleci?token=asdfasdf', foo: 'bar'

        expect(response).to be_forbidden
      end
    end
  end
end
