# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EventsController' do
  describe 'POST #create' do
    context 'with a cookie' do
      before do
        login_with_omniauth(email: 'alice@fundingcircle.com')
      end

      it 'saves the event' do
        post '/events/circleci', params: { foo: 'bar' }

        expect(response).to be_ok
        expect(response.headers).to have_key('Set-Cookie')

        event = Events::CircleCiEvent.last
        expect(event.details).to eq('foo' => 'bar')
      end

      context 'with a return_to param' do
        context 'when return_to is a relative path' do
          it 'redirects to the path' do
            post '/events/circleci', params: { return_to: '/my/projection?with=data' }

            expect(response).to redirect_to('/my/projection?with=data')
          end
        end

        context 'when return_to is an absolute path' do
          it 'ignores the domain and just redirects to the path' do
            post '/events/circleci', params: { return_to: 'http://evil.com/magic/url?with=query' }

            expect(response).to redirect_to('/magic/url?with=query')
          end
        end

        context 'when return_to is not a valid path' do
          it 'does not redirect' do
            post '/events/circleci', params: { return_to: 'TOTALLY NOT VALID' }

            expect(response).to_not have_http_status(302), 'We should not redirect'
          end
        end

        context 'when return_to is blank' do
          it 'does not redirect' do
            post '/events/circleci', params: { return_to: '' }

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
        post "/events/circleci?token=#{token}", params: {foo: 'bar', token: 'the payloads token'}

        expect(response).to be_ok

        event = Events::CircleCiEvent.last
        expect(event.details).to eq('foo' => 'bar', 'token' => 'the payloads token')
      end

      it 'discards duplicated data' do
        post(
          "/events/circleci?token=#{token}",
          params: {
            foo: 'bar',
            token: 'the payloads token',
            event: { foo: 'bar', token: 'the payloads token' }
          },
        )

        expect(response).to be_ok

        event = Events::CircleCiEvent.last
        expect(event.details).to eq('foo' => 'bar', 'token' => 'the payloads token')
      end

      it 'does not create authorised session' do
        post "/events/circleci?token=#{token}", params: {foo: 'bar', token: 'the payloads token'}

        expect(Events::CircleCiEvent.count).to eq(1)

        # subsequent post without token should not work
        post '/events/circleci', params: { more: 'data' }
        expect(response).to be_forbidden

        expect(Events::CircleCiEvent.count).to eq(1)
      end
    end

    context 'with no token' do
      it 'returns 403 Forbidden' do
        post '/events/circleci', params: { foo: 'bar' }

        expect(response).to be_forbidden
      end
    end

    context 'with an invalid token' do
      it 'returns 403 Forbidden' do
        post '/events/circleci?token=asdfasdf', params: { foo: 'bar' }

        expect(response).to be_forbidden
      end
    end

    context 'when the event is not valid' do
      before do
        login_with_omniauth(email: 'test@example.com')
      end

      describe 'forbidden action' do
        class ForbiddenEvent < Events::BaseEvent
          validate -> { errors.add :base, 'forbidden' }
        end

        before do
          expect_any_instance_of(Factories::EventFactory).to receive(:build).and_return(ForbiddenEvent.new)
        end

        it 'will return 403 Forbidden if there is a base error for the event' do
          post '/events/test', params: { foo: 'bar' }

          expect(response).to be_forbidden
        end

        it 'will not redirect event if there is return_to' do
          post '/events/test', params: { return_to: '/my/projection?with=data' }

          expect(response).to be_forbidden
          expect(response['Location']).to be_blank
        end
      end

      describe 'invalid event data' do
        class CustomEvent < Events::BaseEvent
          attr_accessor :name
          validates :name, presence: true
        end

        before do
          expect_any_instance_of(Factories::EventFactory).to receive(:build).and_return(CustomEvent.new)
        end

        it 'will return 400 if there is a validation error' do
          post '/events/test', params: { foo: 'bar' }

          expect(response).to be_bad_request
        end

        it 'will redirect back with an error flash if there is return_to' do
          post '/events/test', params: { return_to: '/my/projection?with=data' }

          expect(response).to redirect_to('/my/projection?with=data')
          expect(flash[:error]).to be_present
        end
      end
    end
  end
end
