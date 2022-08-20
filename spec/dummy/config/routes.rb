# frozen_string_literal: true

Rails.application.routes.draw do
  mount_graphql_devise_for User, at: '/api/v1/graphql_auth', base_controller: ApplicationController, operations: {
    login:    Mutations::Login,
    register: Mutations::Register
  }, additional_mutations: {
    register_confirmed_user: Mutations::RegisterConfirmedUser
  }, additional_queries: {
    public_user: Resolvers::PublicUser
  }

  mount_graphql_devise_for(
    Admin,
    authenticatable_type: Types::CustomAdminType,
    skip:                 [:register],
    operations:           {
      update_password_with_token: Mutations::ResetAdminPasswordWithToken
    },
    at:                   '/api/v1/admin/graphql_auth'
  )

  mount_graphql_devise_for(
    Guest,
    only: [:login, :logout, :register],
    at:   '/api/v1/guest/graphql_auth'
  )

  mount_graphql_devise_for(
    Users::Customer,
    only: [:login],
    at:   '/api/v1/user_customer/graphql_auth'
  )

  get '/api/v1/graphql', to: 'api/v1/graphql#graphql'
  post '/api/v1/graphql', to: 'api/v1/graphql#graphql'
  post '/api/v1/interpreter', to: 'api/v1/graphql#interpreter'
end
