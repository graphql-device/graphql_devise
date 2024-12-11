# frozen_string_literal: true

module GraphqlDevise
  module Types
    class CredentialType < BaseType
      field :access_token,  String, null: false
      field :uid,           String, null: false
      field :token_type,    String, null: false
      field :client,        String, null: false
      field :expiry,        Int,    null: false
      field :authorization, String, null: false

      def access_token
        object[DeviseTokenAuth.headers_names[:"access-token"]]
      end

      def uid
        object[DeviseTokenAuth.headers_names[:uid]]
      end

      def token_type
        object[DeviseTokenAuth.headers_names[:"token-type"]]
      end

      def client
        object[DeviseTokenAuth.headers_names[:client]]
      end

      def expiry
        object[DeviseTokenAuth.headers_names[:expiry]]
      end

      def authorization
        object[DeviseTokenAuth.headers_names[:authorization]]
      end
    end
  end
end
