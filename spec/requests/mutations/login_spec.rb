# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Login Requests' do
  include_context 'with graphql query request'

  let(:password) { '12345678' }

  context 'when using the user model' do
    let!(:user) { create(:user, :confirmed, password: password, email: 'vvega@wallaceinc.com') }
    let(:email) { user.email }
    let(:query) do
      <<-GRAPHQL
        mutation {
          userLogin(
            email: "#{email}",
            password: "#{password}"
          ) {
            user { email name signInCount }
            credentials { accessToken uid tokenType client expiry authorization }
          }
        }
      GRAPHQL
    end

    before { post_request }

    context 'when user is able to login' do
      context 'when credentials are valid' do
        it 'return credentials in headers/field and user information' do
          expect(response).to include_auth_headers
          expect(user.reload.tokens.keys).to include(response.headers['client'])
          expect(json_response[:data][:userLogin]).to match(
            user:        { email: user.email, name: user.name, signInCount: 1 },
            credentials: {
              accessToken:   response.headers['access-token'],
              uid:           response.headers['uid'],
              tokenType:     response.headers['token-type'],
              client:        response.headers['client'],
              expiry:        response.headers['expiry'].to_i,
              authorization: response.headers['Authorization']
            }
          )
          expect(json_response[:errors]).to be_nil
        end

        context 'when email address uses different casing' do
          let(:email) { 'vVeGa@wallaceinc.com' }

          it 'honors devise configuration for case insensitive fields' do
            expect(response).to include_auth_headers
            expect(json_response[:data][:userLogin]).to include(
              user: { email: user.email, name: user.name, signInCount: 1 }
            )
          end
        end
      end

      context 'when credentials are invalid' do
        let(:user) { create(:user, :confirmed, password: 'not guessing it ;)') }

        it 'returns bad credentials error' do
          expect(response).not_to include_auth_headers
          expect(json_response[:data][:userLogin]).to be_nil
          expect(json_response[:errors]).to contain_exactly(
            hash_including(message: 'Invalid login credentials. Please try again.', extensions: { code: 'USER_ERROR' })
          )
        end
      end
    end

    context 'when user is not confirmed' do
      let(:user) { create(:user, password: password) }

      it 'returns a must confirm account message' do
        expect(response).not_to include_auth_headers
        expect(json_response[:data][:userLogin]).to be_nil
        expect(json_response[:errors]).to contain_exactly(
          hash_including(
            message:    "A confirmation email was sent to your account at '#{user.email}'. You must follow the " \
                        "instructions in the email before your account can be activated",
            extensions: { code: 'USER_ERROR' }
          )
        )
      end
    end

    context 'when user is locked' do
      let(:user) { create(:user, :confirmed, :locked, password: password) }

      it 'returns a must confirm account message' do
        expect(response).not_to include_auth_headers
        expect(json_response[:data][:userLogin]).to be_nil
        expect(json_response[:errors]).to contain_exactly(
          hash_including(
            message:    'Your account has been locked due to an excessive number of unsuccessful sign in attempts.',
            extensions: { code: 'USER_ERROR' }
          )
        )
      end
    end

    context 'when invalid for authentication' do
      let(:user) { create(:user, :confirmed, :auth_unavailable, password: password) }

      it 'returns a must confirm account message' do
        expect(response).not_to include_auth_headers
        expect(json_response[:data][:userLogin]).to be_nil
        expect(json_response[:errors]).to contain_exactly(
          hash_including(message: 'Invalid login credentials. Please try again.', extensions: { code: 'USER_ERROR' })
        )
      end
    end
  end

  context 'when using the admin model' do
    let(:admin) { create(:admin, :confirmed, password: password) }
    let(:query) do
      <<-GRAPHQL
        mutation {
          adminLogin(
            email: "#{admin.email}",
            password: "#{password}"
          ) {
            authenticatable { email customField }
          }
        }
      GRAPHQL
    end

    before { post_request('/api/v1/admin/graphql_auth') }

    it 'works alongside the user mount point' do
      expect(json_response[:data][:adminLogin]).to include(
        authenticatable: { email: admin.email, customField: "email: #{admin.email}" }
      )
    end
  end

  context 'when using the guest model' do
    let(:guest) { create(:guest, :confirmed, password: password) }
    let(:query) do
      <<-GRAPHQL
        mutation {
          guestLogin(
            email: "#{guest.email}",
            password: "#{password}"
          ) {
            authenticatable { email }
          }
        }
      GRAPHQL
    end

    before { post_request }

    it 'works alongside the user mount point' do
      expect(json_response[:data][:guestLogin]).to include(
        authenticatable: { email: guest.email }
      )
    end
  end

  context 'when using the Users::Customer model' do
    let(:customer) { create(:users_customer, password: password) }
    let(:query) do
      <<-GRAPHQL
        mutation {
          usersCustomerLogin(
            email: "#{customer.email}",
            password: "#{password}"
          ) {
            authenticatable { email }
          }
        }
      GRAPHQL
    end

    before { post_request }

    it 'works alongside the user mount point' do
      expect(json_response[:data][:usersCustomerLogin]).to include(
        authenticatable: { email: customer.email }
      )
    end
  end

  if DeviseTokenAuth.respond_to?(:cookie_enabled)
    context 'when using cookies for auth' do
      let!(:user) { create(:user, :confirmed, password: password, email: 'vvega@wallaceinc.com') }
      let(:email) { user.email }
      let(:query) do
        <<-GRAPHQL
          mutation {
            userLogin(
              email: "#{email}",
              password: "#{password}"
            ) {
              authenticatable { email }
              credentials { accessToken uid tokenType client expiry }
            }
          }
        GRAPHQL
      end

      around do |example|
        DeviseTokenAuth.cookie_enabled = true
        example.run
        DeviseTokenAuth.cookie_enabled = false
      end

      before { post_request('/api/v1/graphql') }

      it 'honors DTA configuration of setting auth info in cookies' do
        cookie = cookies.get_cookie('auth_cookie')
        expect(JSON.parse(cookie.value).keys).to include('uid', 'access-token', 'client')
      end
    end
  end
end
