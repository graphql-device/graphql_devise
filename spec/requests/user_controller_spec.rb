require 'rails_helper'

RSpec.describe "Integrations with the user's controller" do
  include_context 'with graphql query request'

  let(:user) { create(:user, :confirmed) }

  describe 'publicField' do
    let(:query) do
      <<-GRAPHQL
        query {
          publicField
        }
      GRAPHQL
    end

    context 'when using a regular schema' do
      before { post_request('/api/v1/graphql') }

      it 'does not require authentication' do
        expect(json_response[:data][:publicField]).to eq('Field does not require authentication')
      end
    end

    context 'when using an interpreter schema' do
      before { post_request('/api/v1/interpreter') }

      it 'does not require authentication' do
        expect(json_response[:data][:publicField]).to eq('Field does not require authentication')
      end
    end

    context 'when using the failing route' do
      it 'raises an invalid resource_name error' do
        expect { post_request('/api/v1/failing') }.to raise_error(
          GraphqlDevise::Error,
          'Invalid resource_name `fail` provided to `graphql_context`. Possible values are: [:user, :admin, :guest, :users_customer].'
        )
      end
    end
  end

  describe 'privateField' do
    let(:query) do
      <<-GRAPHQL
        query {
          privateField
        }
      GRAPHQL
    end

    context 'when using a regular schema' do
      before { post_request('/api/v1/graphql') }

      context 'when user is authenticated' do
        let(:headers) { user.create_new_auth_token }

        it 'allow to perform the query' do
          expect(json_response[:data][:privateField]).to eq('Field will always require authentication')
        end
      end

      context 'when user is not authenticated' do
        it 'returns a must sign in error' do
          expect(json_response[:errors]).to contain_exactly(
            hash_including(message: 'privateField field requires authentication', extensions: { code: 'AUTHENTICATION_ERROR' })
          )
        end
      end
    end

    context 'when using an interpreter schema' do
      before { post_request('/api/v1/interpreter') }

      context 'when user is authenticated' do
        let(:headers) { user.create_new_auth_token }

        it 'allow to perform the query' do
          expect(json_response[:data][:privateField]).to eq('Field will always require authentication')
        end
      end

      context 'when user is not authenticated' do
        it 'returns a must sign in error' do
          expect(json_response[:errors]).to contain_exactly(
            hash_including(message: 'privateField field requires authentication', extensions: { code: 'AUTHENTICATION_ERROR' })
          )
        end
      end
    end
  end

  describe 'dummyMutation' do
    let(:query) do
      <<-GRAPHQL
        mutation {
          dummyMutation
        }
      GRAPHQL
    end

    context 'when using a regular schema' do
      before { post_request('/api/v1/graphql') }

      context 'when user is authenticated' do
        let(:headers) { user.create_new_auth_token }

        it 'allow to perform the query' do
          expect(json_response[:data][:dummyMutation]).to eq('Necessary so GraphQL gem does not complain about empty mutation type')
        end
      end

      context 'when user is not authenticated' do
        it 'returns a must sign in error' do
          expect(json_response[:errors]).to contain_exactly(
            hash_including(message: 'dummyMutation field requires authentication', extensions: { code: 'AUTHENTICATION_ERROR' })
          )
        end
      end
    end

    context 'when using an interpreter schema' do
      before { post_request('/api/v1/interpreter') }

      context 'when user is authenticated' do
        let(:headers) { user.create_new_auth_token }

        it 'allow to perform the query' do
          expect(json_response[:data][:dummyMutation]).to eq('Necessary so GraphQL gem does not complain about empty mutation type')
        end
      end

      context 'when user is not authenticated' do
        it 'returns a must sign in error' do
          expect(json_response[:errors]).to contain_exactly(
            hash_including(message: 'dummyMutation field requires authentication', extensions: { code: 'AUTHENTICATION_ERROR' })
          )
        end
      end
    end
  end

  describe 'user' do
    let(:query) do
      <<-GRAPHQL
        query {
          user(
            id: #{user.id}
          ) {
            id
            email
          }
        }
      GRAPHQL
    end

    context 'when using a regular schema' do
      before { post_request('/api/v1/graphql') }

      context 'when user is authenticated' do
        let(:headers) { user.create_new_auth_token }

        it 'allow to perform the query' do
          expect(json_response[:data][:user]).to match(
            email: user.email,
            id:    user.id
          )
        end
      end

      context 'when user is not authenticated' do
        it 'returns a must sign in error' do
          expect(json_response[:errors]).to contain_exactly(
            hash_including(message: 'user field requires authentication', extensions: { code: 'AUTHENTICATION_ERROR' })
          )
        end
      end
    end

    context 'when using an interpreter schema' do
      before { post_request('/api/v1/interpreter') }

      context 'when user is authenticated' do
        let(:headers) { user.create_new_auth_token }

        it 'allow to perform the query' do
          expect(json_response[:data][:user]).to match(
            email: user.email,
            id:    user.id
          )
        end
      end

      context 'when user is not authenticated' do
        # Interpreter schema fields are public unless specified otherwise (plugin setting)
        it 'allow to perform the query' do
          expect(json_response[:data][:user]).to match(
            email: user.email,
            id:    user.id
          )
        end
      end
    end
  end
end
