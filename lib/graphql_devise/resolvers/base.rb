# frozen_string_literal: true

require 'devise_token_auth/version'

module GraphqlDevise
  module Resolvers
    class Base < GraphQL::Schema::Resolver
      include ControllerMethods
    end
  end
end
