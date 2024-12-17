# GraphqlDevise
[![Build Status](https://circleci.com/gh/graphql-devise/graphql_devise.svg?style=svg)](https://app.circleci.com/pipelines/github/graphql-devise/graphql_devise)
[![Coverage Status](https://coveralls.io/repos/github/graphql-devise/graphql_devise/badge.svg)](https://coveralls.io/github/graphql-devise/graphql_devise)
[![Gem Version](https://badge.fury.io/rb/graphql_devise.svg)](https://badge.fury.io/rb/graphql_devise)

GraphQL interface on top of the [Devise Token Auth](https://github.com/lynndylanhurley/devise_token_auth) (DTA) gem.

## Table of Contents

<!--ts-->
* [GraphqlDevise](#graphqldevise)
   * [Table of Contents](#table-of-contents)
   * [Introduction](#introduction)
   * [Installation](#installation)
      * [Running the Generator](#running-the-generator)
         * [Mounting the Schema in a Separate Route](#mounting-the-schema-in-a-separate-route)
         * [Mounting Operations in an Existing Schema (&gt; v0.12.0)](#mounting-operations-in-an-existing-schema--v0120)
   * [Usage](#usage)
      * [Mounting Auth Schema on a Separate Route](#mounting-auth-schema-on-a-separate-route)
      * [Mounting Operations In an Existing Schema](#mounting-operations-in-an-existing-schema)
      * [Available Mount Options](#available-mount-options)
      * [Available Operations](#available-operations)
      * [Configuring Model](#configuring-model)
      * [Email Reconfirmation](#email-reconfirmation)
         * [Current flow](#current-flow)
      * [Customizing Email Templates](#customizing-email-templates)
      * [I18n](#i18n)
      * [Authenticating Controller Actions](#authenticating-controller-actions)
         * [Authenticate Resource in the Controller (&gt;= v0.15.0)](#authenticate-resource-in-the-controller--v0150)
            * [Authentication Options](#authentication-options)
      * [Making Requests](#making-requests)
         * [Introspection query](#introspection-query)
         * [Mutations](#mutations)
      * [Reset Password Flow](#reset-password-flow)
      * [More Configuration Options](#more-configuration-options)
         * [Devise Token Auth Initializer](#devise-token-auth-initializer)
         * [Devise Initializer](#devise-initializer)
      * [GraphQL 2.0 Support (&gt;= v1.0.0)](#graphql-20-support--v100)
      * [GraphQL Interpreter](#graphql-interpreter)
      * [Using Alongside Standard Devise](#using-alongside-standard-devise)
   * [Changelog](#changelog)
   * [Future Work](#future-work)
   * [Buy Us a Coffee](#buy-us-a-coffee)
            * [BTC](#btc)
            * [ADA](#ada)
   * [Contributing](#contributing)
   * [License](#license)

<!-- Added by: mcelicalderon, at: Wed Aug  3 22:04:10 -05 2022 -->

<!--te-->

## Introduction
Graphql-Devise heavily relies on 3 gems:
- [GraphQL Ruby](https://github.com/rmosolgo/graphql-ruby)
- [Devise Token Auth](https://github.com/lynndylanhurley/devise_token_auth) (DTA)
- [Devise](https://github.com/heartcombo/devise) (which is a DTA dependency)

This gem provides a GraphQL interface on top of DTA which is designed for REST APIs. Features like token management, token expiration and everything up until using the actual GraphQL schema is still controlled by DTA. For that reason the gem's generator invokes DTA and Devise generators and creates initializer files for each one of them.

**We strongly recommend getting familiar with [DTA documentation](https://github.com/lynndylanhurley/devise_token_auth) to use this gem to its full potential**.
More configuration details available in [configuration section](#more-configuration-options)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'graphql_devise'
```

And then execute:
```bash
$ bundle
```

### Running the Generator
Graphql Devise generator will execute `Devise` and `Devise Token Auth` generators to setup the gems in your project. You can customize them to your needs using their initializer files(one per gem) as usual.

```bash
$ bundle exec rails generate graphql_devise:install
```
The generator accepts 2 params and 1 option:
- `user_class`: Model name in which `Devise` modules will be included. This uses a `find or create` strategy. Defaults to `User`.
- `mount_path`: Path in which the dedicated graphql schema for devise will be mounted. Defaults to `/graphql_auth`.
- `--mount`: This options is available starting from `v0.12.0`, it allows you to mount the operations in your own schema instead of a dedicated one. When provided `mount_path` param is ignored.

#### Mounting the Schema in a Separate Route

To configure the gem to use a separate schema, the generator will use `user_class` and `mount_path` params.
The route will be mounted in `config/routes.rb`. For instance the executing:

```bash
$ bundle exec rails g graphql_devise:install Admin api/auth
```

Will do the following:
- Execute `Devise` install generator
- Execute `Devise Token Auth` install generator with `Admin` and `api/auth` as params
  - Find or create `Admin` model
  - Add `devise` modules to `Admin` model
  - Other changes that you can find [here](https://devise-token-auth.gitbook.io/devise-token-auth/config)
- Add the route to `config/routes.rb`
  - `mount_graphql_devise_for Admin, at: 'api/auth'`

`Admin` could be any model name you are going to be using for authentication,
and `api/auth` could be any mount path you would like to use for auth.

**Important**
 - Remember that by default this gem mounts a completely separate GraphQL schema on a separate controller in the route provided by the `at` option in the `mount_graphql_devise_for` method in the `config/routes.rb` file. If no `at` option is provided, the route will be `/graphql_auth`.
 - Avoid passing the `--mount` option if you want to use a separate route and schema.

#### Mounting Operations in an Existing Schema (> v0.12.0)
To configure the gem to use an existing GQL schema use the `--mount` option.
For instance the executing:

```bash
$ bundle exec rails g graphql_devise:install Admin --mount MySchema
```

Will do the following:
- Execute `Devise` install generator
- Execute `Devise Token Auth` install generator with `Admin` and `api/auth` as params
  - Find or create `Admin` model
  - Add `devise` modules to `Admin` model
  - Other changes that you can find [here](https://devise-token-auth.gitbook.io/devise-token-auth/config)
  - Add `SchemaPlugin` to the specified schema.


**Important**
 - When using the `--mount` option the `mount_path` param is ignored.
 - The generator will look for your schema under `app/graphql/` directory. We are expecting the name of the file is the same as the as the one passed in the mount option transformed with `underscore`. In the example, passing `MySchema`, will try to find the file `app/graphql/my_schema.rb`.
 - You can actually mount a resource's auth schema in a separate route and in your app's schema at the same time, but that's probably not a common scenario.

## Usage

GraphqlDevise operations can be used in two ways:
- Using a [separate schema](#mounting-auth-schema-on-a-separate-route) via `mount_graphql_devise_for` helper in the routes file.
- Using [your own schema](#mounting-operations-into-your-own-schema) by adding a plugin in the class.


Creating a separate schema is the default option, the generator will do that by default.

### Mounting Auth Schema on a Separate Route

You can mount this gem's GraphQL auth schema in your routes file like this:

```ruby
# config/routes.rb

Rails.application.routes.draw do
  mount_graphql_devise_for(
    User,
    at: 'api/v1',
    authenticatable_type: Types::MyCustomUserType,
    operations: {
      login: Mutations::Login
    },
    skip: [:register],
    # optional, use only if you need a specific base controller to mount the new actions
    base_controller: ApiController,
    additional_mutations: {
      # generates mutation { adminUserSignUp }
      admin_user_sign_up: Mutations::AdminUserSignUp
    },
    additional_queries: {
      # generates query { publicUserByUuid }
      public_user_by_uuid: Resolvers::UserByUuid
    }
  )
end
```
This can be done using the generator or manually.
The second argument of the `mount_graphql_devise` method is a hash of options where you can
customize how the queries and mutations are mounted into the schema. For a list of available
options go [here](#available-mount-options)

### Mounting Operations In an Existing Schema

Starting with `v0.12.0` you can mount the GQL operations provided by this gem into an
existing schema in your app.

```ruby
# app/graphql/dummy_schema.rb

class DummySchema < GraphQL::Schema
  # It's important that this line goes before setting the query and mutation type on your
  # schema in graphql versions < 1.10.0
  use GraphqlDevise::SchemaPlugin.new(
    query:            Types::QueryType,
    mutation:         Types::MutationType,
    resource_loaders: [
      GraphqlDevise::ResourceLoader.new(User, only: [:login, :confirm_registration_with_token])
    ]
  )

  mutation(Types::MutationType)
  query(Types::QueryType)
end
```
The example above describes just one of the possible scenarios you might need.
The second argument of the `GraphqlDevise::ResourceLoader` initializer is a hash of
options where you can customize how the queries and mutations are mounted into the schema.
For a list of available options go [here](#available-mount-options).

It's important to use the plugin in your schema before assigning the mutation and query type to
it in graphql versions `< 1.10.0`. Otherwise the auth operations won't be available.

You can provide as many resource loaders as you need to the `resource_loaders` option, and each
of those will be loaded into your schema. These are the options you can initialize the
`SchemaPlugin` with:

1. `query`: This param is mandatory unless you skip all queries via the resource loader
options. This should be the same `QueryType` you provide to the `query` method
in your schema.
1. `mutation`: This param mandatory unless you skip all mutations via the resource loader
options. This should be the same `MutationType` you provide to the `mutation` method
in your schema.
1. `resource_loaders`: This is an optional array of `GraphqlDevise::ResourceLoader` instances.
Here is where you specify the operations that you want to load into your app's schema.
If no loader is provided, no operations will be added to your schema, but you will still be
able to authenticate queries and mutations selectively. More on this in the controller
authentication [section](#authenticating-controller-actions).
1. `authenticate_default`: This is a boolean value which is `true` by default. This value
defines what is the default behavior for authentication in your schema fields. `true` means
every root level field requires authentication unless specified otherwise using the
`authenticate: false` option on the field. `false` means your root level fields won't require
authentication unless specified otherwise using the `authenticate: true` option on the field.
1. `unauthenticated_proc`: This param is optional. Here you can provide a proc that receives
one argument (field name) and is called whenever a field that requires authentication
is called without an authenticated resource. By default a `GraphQL::ExecutionError` will be
raised if authentication fails. This will provide a GQL like error message on the response.
1. `public_introspection`: The [introspection query](https://graphql.org/learn/introspection/) is a very useful GQL resource that provides
information about what queries the schema supports. This query is very powerful and
there may be some case in which you want to limit its usage to authenticated users.
To accomplish this the schema plugin provides the `public_introspection` option. This option
accepts a boolean value and by default will consider introspection queries public in all
environments but production.

### Available Mount Options
Both the `mount_graphql_devise_for` method and the `GraphqlDevise::ResourceLoader` class
take the same options. So, wether you decide to mount this gem in a separate route
from your main application's schema or you use our `GraphqlDevise::SchemaPlugin` to load
this gem's auth operation into your schema, these are the options you can provide as a hash.

```ruby
# Using the mount method in your config/routes.rb file
mount_graphql_devise_for(User, {})

# Providing options to a GraphqlDevise::ResourceLoader
GraphqlDevise::ResourceLoader.new(User, {})
```

1. `at`: Route where the GraphQL schema will be mounted on the Rails server.
In [this example](#mounting-auth-schema-on-a-separate-route) your API will have
these two routes: `POST /api/v1/graphql_auth` and `GET /api/v1/graphql_auth`.
If this option is not specified, the schema will be mounted at `/graphql_auth`. **This option only works if you are using the mount method.**
1. `operations`: Specifying this is optional. Here you can override default
behavior by specifying your own mutations and queries for every GraphQL operation.
Check available operations in this file [mutations](https://github.com/graphql-devise/graphql_devise/blob/b5985036e01ea064e43e457b4f0c8516f172471c/lib/graphql_devise/rails/routes.rb#L19)
and [queries](https://github.com/graphql-devise/graphql_devise/blob/b5985036e01ea064e43e457b4f0c8516f172471c/lib/graphql_devise/rails/routes.rb#L41).
All mutations and queries are built so you can extend default behavior just by extending
our default classes and yielding your customized code after calling `super`, example
[here](https://github.com/graphql-devise/graphql_devise/blob/b5985036e01ea064e43e457b4f0c8516f172471c/spec/dummy/app/graphql/mutations/login.rb#L6).
1. `authenticatable_type`: By default, the gem will add an `authenticatable` field to every mutation
and an `authenticatable` type to every query. Gem will try to use `Types::<model>Type` by
default, so in our example you could define `Types::UserType` and every query and mutation
will use it. But, you can override this type with this option like in the example.
1. `base_controller`: Specifying this is optional. By default the controller used to mount the route is
`GraphqlDevise::ApplicationController` which inherits from `ActionController::API` or `ActionController::Base`
depending on the rails version of the main project. This option allows you to set the controller used as the parent of
the controller where the route will be mounted. This config is similar to `Devise`'s `base_controller` config but in
this case each route can have a different parent controller. **This option only works if you are using the mount method.**
1. `skip`: An array of the operations that should not be available in the authentication schema. All these operations are
symbols and should belong to the list of available operations in the gem.
1. `only`: An array of the operations that should be available in the authentication schema. The `skip` and `only` options are
mutually exclusive, an error will be raised if you pass both to the mount method.
1. `additional_mutations`: Here you can add as many mutations as you
need, for those features that don't fully match the provided default mutations and queries.
You need to provide a hash to this option, and
each key will be the name of the mutation on the schema. Also, the value provided must be a valid mutation.
This is similar to what you can accomplish with
[devise_scope](https://www.rubydoc.info/github/heartcombo/devise/master/ActionDispatch/Routing/Mapper%3Adevise_for).
1. `additional_queries`: Here you can add as many queries as you need,
for those features that don't fully match the provided default mutations and queries.
You need to provide a hash to this option, and
each key will be the name of the query on the schema. Also, the value provided must be a valid Resolver.
This is also similar to what you can accomplish with
[devise_scope](https://www.rubydoc.info/github/heartcombo/devise/master/ActionDispatch/Routing/Mapper%3Adevise_for).

Additional mutations and queries will be added to the schema regardless
of other options you might have specified like `skip` or `only`.
Additional queries and mutations is usually a good place for other
operations on your schema that require no authentication (like sign_up).
Also by adding them through the mount method, your mutations and
resolvers can inherit from our [base mutation](https://github.com/graphql-devise/graphql_devise/blob/master/app/graphql/graphql_devise/mutations/base.rb)
or [base resolver](https://github.com/graphql-devise/graphql_devise/blob/master/app/graphql/graphql_devise/resolvers/base.rb)
respectively, to take advantage of some of the methods provided by devise
just like with `devise_scope`

### Available Operations
The following is a list of the symbols you can provide to the `operations`, `skip` and `only` options of the mount method:
```ruby
:login
:logout
:register
:update_password_with_token
:send_password_reset_with_token
:resend_confirmation_with_token
:confirm_registration_with_token
```

### Configuring Model
Just like with Devise and DTA, you need to include a module in your authenticatable model,
so with our example, your user model will have to look like this:
```ruby
# app/models/user.rb

class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :lockable,
         :validatable,
         :confirmable

  # including after calling the `devise` method is important.
  include GraphqlDevise::Authenticatable
end
```

The install generator can do this for you if you specify the `user_class` option.
See [Installation](#installation) for details.

### Email Reconfirmation
We want reconfirmable in this gem to work separately
from DTA's or Devise (too much complexity in the model based on callbacks).

Email reconfirmation is supported just like in Devise and DTA, but we want reconfirmable
in this gem to work on model basis instead of having a global configuration like in Devise.
**For this reason Devise's global `reconfirmable` setting is ignored.**

For a resource to be considered reconfirmable it has to meet 2 conditions:
1. Include the `:confirmable` module.
1. Has an `unconfirmed_email` column in the resource's table.

In order to trigger the reconfirmation email in a reconfirmable resource, you simply need
to call a different update method on your resource,`update_with_email`.
When the resource is not reconfirmable or the email is not updated, this method behaves exactly
the same as ActiveRecord's `update`.

#### Current flow
`update_with_email` requires one additional attribute when email will change or an error
will be raised:

- `confirmation_url`: The full url of your client application. The confirmation email will contain this url plus
a confirmation token. You need to call `confirmRegistrationWithToken` with the given token on
your client application.

So, it's up to you where you require confirmation of changing emails.
Here's a demonstration on the method usage:
```ruby
user.update_with_email(
  name:             'New Name',
  email:            'new@domain.com',
  confirmation_url: 'https://google.com'
)
```

### Customizing Email Templates
The approach of this gem is a bit different from DeviseTokenAuth. We have placed our templates in `app/views/graphql_devise/mailer`,
so if you want to change them, place yours on the same dir structure on your Rails project. You can customize these two templates:
1. `app/views/graphql_devise/mailer/confirmation_instructions.html.erb`
1. `app/views/graphql_devise/mailer/reset_password_instructions.html.erb`

The main reason for this difference is just to make it easier to have both Standard `Devise` and this gem running at the same time.
Check [these files](app/views/graphql_devise/mailer) to see the available helper methods you can use in your views.

### I18n
GraphQL Devise supports locales. For example, the `graphql_devise.confirmations.send_instructions` locale setting supports the `%{email}` variable in case you would like to include it in the resend confirmation instructions for the user. Take a look at our [locale file](https://github.com/graphql-devise/graphql_devise/blob/master/config/locales/en.yml) to see all of the available messages.

Keep in mind that if your app uses multiple locales, you should set the `I18n.locale` accordingly. You can learn how to do this [here](https://guides.rubyonrails.org/i18n.html).

### Authenticating Controller Actions
When mounting the operation is in you own schema instead of a dedicated one, you will need to authenticate users in your controllers, just like in DTA. There are 2 alternatives to accomplish this.

#### Authenticate Resource in the Controller (>= v0.15.0)
This authentication mechanism sets the resource by token in the controller, or it doesn't if credentials are invalid.
You simply need to pass the return value of our `gql_devise_context` method in the context of your
GQL schema execution like this:

```ruby
# app/controllers/my_controller.rb

class MyController < ApplicationController
  include GraphqlDevise::SetUserByToken

  def my_action
    result = DummySchema.execute(params[:query], context: gql_devise_context(User))
    render json: result unless performed?
  end
end
```
`gql_devise_context` receives as many models as you need to authenticate in the request, like this:
```ruby
# app/controllers/my_controller.rb

class MyController < ApplicationController
  include GraphqlDevise::SetUserByToken

  def my_action
    result = DummySchema.execute(params[:query], context: gql_devise_context(User, Admin))
    render json: result unless performed?
  end
end
```
Internally in your own mutations and queries a key `current_resource` will be available in
the context if a resource was successfully authenticated or `nil` otherwise.

Keep in mind that sending multiple models to the `gql_devise_context` method means that depending
on who makes the request, the context value `current_resource` might contain instances of the
different models you provided.

**Note:** If for any reason you need more control over how users are authenticated, you can use the `authenticate_model`
method anywhere in your controller. The method will return the authenticated resource or nil if authentication fails.
It will also set the instance variable `@resource` in the controller.

Please note that by using this mechanism your GQL schema will be in control of what queries are
restricted to authenticated users and you can only do this at the root level fields of your GQL
schema. Configure the plugin as explained [here](#mounting-operations-into-your-own-schema)
so this can work.

##### Authentication Options
Whether you setup authentications as a default in the plugin, or you do it at the field level,
these are the options you can use:
1. **Any truthy value:** If `current_resource` is not `.present?`, query will return an authentication error.
1. **A callable object:** Provided object will be called with `current_resource` as the only argument if `current_resource` is `.present?`. If return value of the callable object is false, query will return an authentication error.

In your main app's schema this is how you might specify if a field needs to be authenticated or not:
```ruby
module Types
  class QueryType < Types::BaseObject
    # user field used the default set in the Plugin's initializer
    field :user, resolver: Resolvers::UserShow
    # this field will never require authentication
    field :public_field, String, null: false, authenticate: false
    # this field requires authentication
    field :private_field, String, null: false, authenticate: true
    # this field requires authenticated users to also be admins
    field :admin_field, String, null: false, authenticate: ->(user) { user.admin? }
  end
end
```

### Making Requests
Here is a list of the available mutations and queries assuming your mounted model is `User`.

#### Introspection query
If you are using the schema plugin, you can require authentication before doing an introspection query by modifying the `public_introspection` option of the plugin. Check the [plugin config section](#mounting-operations-into-your-own-schema) for more information.

If you want to completely disable introspection queries, refer to [Disable Introspection](#disable-introspection)

#### Mutations

Operation | Description | Example
:--- | :--- | :------------------:
login | This mutation has a second field by default. `credentials` can be fetched directly on the mutation return type.<br>Credentials are still returned in the headers of the response. | userLogin(email: String!, password: String!): UserLoginPayload |
logout | requires authentication headers. Deletes current session if successful. | userLogout: UserLogoutPayload |
register | The parameter `confirmUrl` is optional unless you are using the `confirmable` plugin from Devise in your `resource`'s model. If you have `confirmable` set up, you will have to provide it unless you have `config.default_confirm_success_url` set in `config/initializers/devise_token_auth.rb`. | userRegister(email: String!, password: String!, passwordConfirmation: String!, confirmUrl: String): UserRegisterPayload |
sendPasswordResetWithToken | Sends an email to the provided address with a link to reset the password of the resource. First step of the most recently implemented password reset flow. | userSendPasswordResetWithToken(email: String!, redirectUrl: String!): UserSendPasswordResetWithTokenPayload |
updatePasswordWithToken | Uses a `resetPasswordToken` to update the password of a resource. Second and last step of the most recently implemented password reset flow. | userSendPasswordResetWithToken(resetPasswordToken: String!, password: String!, passwordConfirmation: String!): UserUpdatePasswordWithTokenPayload |
resendConfirmationWithToken | The `UserResendConfirmationWithTokenPayload` will return a `message: String!` that can be used to notify a user what to do after the instructions were sent to them. Email will contain a link to the provided `confirmUrl` and a `confirmationToken` query param. | userResendConfirmationWithToken(email: String!, confirmUrl: String!): UserResendConfirmationWithTokenPayload |

### Reset Password Flow
This gem supports two password recovery flows. The most recently implemented is preferred and
requires less steps. More detail on how it works can be found
[here](docs/usage/reset_password_flow.md).

### More Configuration Options
As mentioned in the introduction there are many configurations that will change how this gem behaves. You can change
this values on the initializer files generated by the installer.

#### Devise Token Auth Initializer
The generated initializer file `config/initializers/devise_token_auth.rb` has all the available options documented
as comments. You can also use
**[DTA's docs](https://devise-token-auth.gitbook.io/devise-token-auth/config/initialization)** as a reference.
In this section the most important configurations will be highlighted.

- **change_headers_on_each_request:** This configurations defaults to `false`. This will allow you to store the
  credentials for as long as the token life_span permits. And you can send the same credentials in each request.
  Setting this to `true` means that tokens will change on each request you make, and the new values will be returned
  in the headers. So your client needs to handle this.
- **batch_request_buffer_throttle:** When change_headers_on_each_request is set to true, you might still want your
  credentials to be valid more than once as you might send parallel request. The duration you set here will
  determine how long the same credentials work after the first request is received.
- **token_lifespan:** This configuration takes a duration and you can set it to a value like
  `1.month`, `2.weeks`, `1.hour`, etc.

**Note:** Remember this gem adds a layer on top of DTA, so some configurations might not apply.

#### Devise Initializer
The generated initializer file `config/initializers/devise_token_auth.rb` has all the available options documented
as comments. You can also use
**[Devise's docs](https://github.com/heartcombo/devise)** as a reference.
In this section the most important configurations will be highlighted.

- **password_length:** You can change this value to validate password length on sign up and password update
  (must enable the validatable module).
- **mailer_sender:** Set it to a string with the sender's email address like `'support@example.com'`.
- **case_insensitive_keys:** Setting a value like `[:email]` will make email field case insensitive on login, sign up, etc.
- **email_regexp:** You can customize the regex that will validate the format of email addresses (must enable the validatable module).

**Note:** Remember this gem adds a layer on top of Devise, so some configurations might not apply.

### GraphQL 2.0 Support (>= v1.0.0)
This gem now supports [GraphQL Ruby](https://github.com/rmosolgo/graphql-ruby) v2.
There's one manual step you need to take in order for this to work.

You need a custom `field_class` in your `MutationType` and `QueryType`. If you don't have one setup already, you can simply add the one
this gem provides, like this:

```ruby
module Types
  class MutationType < BaseObject
    field_class GraphqlDevise::Types::BaseField
  end
end

module Types
  class QueryType < Types::BaseObject
    field_class GraphqlDevise::Types::BaseField
  end
end
```

If you already have a `field_class` defined in any of your types, the only thing you need to do is add another `kwarg`
to that class initializer (`authenticate`) and make that value available through an attribute reader.

The next example is this gem's implementation of a custom class, but you can implement your own however you see fit
as long as you expose an `authenticate` public method with the value that was passed to the initializer.

```ruby
module GraphqlDevise
  module Types
    class BaseField < GraphQL::Schema::Field
      def initialize(*args, authenticate: nil, **kwargs, &block)
        @authenticate = authenticate
        super(*args, **kwargs, &block)
      end

      attr_reader :authenticate
    end
  end
end
```

### GraphQL Interpreter
GraphQL-Ruby `>= 1.9.0` includes a new runtime module which you may use for your schema.
Eventually, it will become the default. You can read more about it
[here](https://graphql-ruby.org/queries/interpreter).

This gem supports schemas using the interpreter and it is recommended as it introduces several
improvements which focus mainly on performance.

### Using Alongside Standard Devise
The DeviseTokenAuth gem allows experimental use of the standard Devise gem to be configured at the same time, for more
information you can check [this answer here](https://github.com/lynndylanhurley/devise_token_auth/blob/2a32f18ccce15638a74e72f6cfde5cf15a808d3f/docs/faq.md#can-i-use-this-gem-alongside-standard-devise).

This gem supports the same and should be easier to handle email templates due to the fact we don't override
standard Devise templates.

### Disable Introspection
`GraphqlDevise::Schema` extends from `GraphQL::Schema`, which allows it to utilize the `disable_introspection_entry_points` method. By calling this method, you can disable introspection entry points in your schema. You can read more about it
[here](https://github.com/rmosolgo/graphql-ruby/blob/master/guides/schema/introspection.md#disabling-introspection).

If you are using the schema plugin and prefer to make introspection queries available only to authenticated users, you can do so by modifying the `public_introspection` option of the plugin. Check the [plugin config section](#mounting-operations-into-your-own-schema) for more information.

## Changelog
Full list of changes in [CHANGELOG.md](CHANGELOG.md)

## Future Work
We will continue to improve the gem and add better docs.

1. Make sure this gem can correctly work alongside DTA and the original Devise gem.
1. Improve DOCS.
1. Add support for unlockable and other Devise modules.
1. Add feature specs for confirm account and reset password flows.

We will continue to build better docs for the gem after this first release, but in the mean time
you can use [our specs](spec/requests) to better understand how to use the gem.
Also, the [dummy app](spec/dummy) used in our specs will give you
a clear idea on how to configure the gem on your Rails application.

## Buy Us a Coffee
If you'd like to support our work, you are welcome to do so!

##### BTC
```
bc1qntlmyl24wuf6y5jyn2vg8kduss57dwtyrcflyq
```
##### ADA
```
addr1q8e8cjzutzptcrfgjgsjl3k4t4xy5ucrmkf2dmq9qn966q8saucty53avujfc9yu9vfk7266auhdx9fz4fsryzeagqds893nfw
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/graphql-devise/graphql_devise.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
