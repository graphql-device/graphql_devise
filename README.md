# GraphqlDevise
[![Build Status](https://travis-ci.org/graphql-devise/graphql_devise.svg?branch=master)](https://travis-ci.org/graphql-devise/graphql_devise)
[![Gem Version](https://badge.fury.io/rb/graphql_devise.svg)](https://badge.fury.io/rb/graphql_devise)

GraphQL interface on top of the [Devise Token Auth](https://github.com/lynndylanhurley/devise_token_auth) (DTA) gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'graphql_devise'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install graphql_devise

## Usage
All configurations for [Devise](https://github.com/plataformatec/devise) and
[Devise Token Auth](https://github.com/lynndylanhurley/devise_token_auth) are
available, so you can read the docs there to customize your options.
Configurations are done via initializer files as usual, one per gem.
You can generate most of the configuration by using DTA's installer while we work
on our own generators like this
```bash
$ rails g devise_token_auth:install User auth
```
`User` could be any model name you are going to be using for authentication,
and `auth` could be anything as we will be removing that from the routes file.

### Mounting Routes
First, you need to mount the gem in the routes file like this
```ruby
# config/routes.rb

Rails.application.routes.draw do
  mount_graphql_devise_for(
    'User',
    at: 'api/v1',
    authenticable_type: Types::MyCustomUserType,
    operations: {
      login: Mutations::Login
    },
    skip: [:sign_up]
  )
end
```
If you used DTA's installer you will have to remove the `mount_devise_token_auth_for`
line.

Here are the options for the mount method:

1. `at`: Route where the GraphQL schema will be mounted on the Rails server. In this example your API will have these two routes: `POST /api/v1/graphql_auth` and `GET /api/v1/graphql_auth`.
If this option is not specified, the schema will be mounted at `/graphql_auth`.
1. `operations`: Specifying this is optional. Here you can override default
behavior by specifying your own mutations and queries for every GraphQL operation.
Check available operations in this file [mutations](https://github.com/graphql-devise/graphql_devise/blob/b5985036e01ea064e43e457b4f0c8516f172471c/lib/graphql_devise/rails/routes.rb#L19)
and [queries](https://github.com/graphql-devise/graphql_devise/blob/b5985036e01ea064e43e457b4f0c8516f172471c/lib/graphql_devise/rails/routes.rb#L41).
All mutations and queries are built so you can extend default behavior just by extending
our default classes and yielding your customized code after calling `super`, example
[here](https://github.com/graphql-devise/graphql_devise/blob/b5985036e01ea064e43e457b4f0c8516f172471c/spec/dummy/app/graphql/mutations/login.rb#L6).
1. `authenticable_type`: By default, the gem will add an `authenticable` field to every mutation
and an `authenticable` type to every query. Gem will try to use `Types::<model>Type` by
default, so in our example you could define `Types::UserType` and every query and mutation
will use it. But, you can override this type with this option like in the example.
1. `skip`: An array of the operations that should not be available in the authentication schema. All these operations are
symbols and should belong to the list of available operations in the gem.
1. `only`: An array of the operations that should be available in the authentication schema. The `skip` and `only` options are
mutually exclusive, an error will be raised if you pass both to the mount method.

#### Available Operations
The following is a list of the symbols you can provide to the `operations`, `skip` and `only` options of the mount method:
```ruby
:login
:logout
:sign_up
:update_password
:send_reset_password
:confirm_account
:check_password_token
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
  include GraphqlDevise::Concerns::Model
end
```

### Customizing Email Templates
The approach of this gem is a bit different from DeviseTokenAuth. We have placed our templates in `app/views/graphql_devise/mailer`,
so if you want to change them, place yours on the same dir structure on your Rails project. You can customize these two templates:
1. `app/views/graphql_devise/mailer/confirmation_instructions.html.erb`
1. `app/views/graphql_devise/mailer/reset_password_instructions.html.erb`

The main reason for this difference is just to make it easier to have both Standard `Devise` and this gem running at the same time.
Check [these files](app/views/graphql_devise/mailer) to see the available helper methods you can use in your views.

### Authenticating Controller Actions
Just like with Devise or DTA, you will need to authenticate users in your controllers.
For this you need to call `authenticate_<model>!` in a before_action hook of your controller.
In our example our model is `User`, so it would look like this:
```ruby
# app/controllers/my_controller.rb

class MyController < ApplicationController
  before_action :authenticate_user!

  def my_action
    render json: { current_user: current_user }
  end
end
```

### Making Requests
Here is a list of the available mutations and queries assuming your mounted model
is `User`.

#### Mutations
1. userLogin
1. userLogout
1. userSignUp
1. userUpdatePassword
1. userSendResetPassword

#### Queries
1. userConfirmAccount
1. userCheckPasswordToken

The reason for having 2 queries is that these 2 are going to be accessed when clicking on
the confirmation and reset password email urls. There is no limitation for making mutation
requests using the `GET` method on the Rails side, but looks like there might be a limitation
on the [Apollo Client](https://www.apollographql.com/docs/apollo-server/v1/requests/#get-requests).

We will continue to build better docs for the gem after this first release, but in the mean time
you can use [our specs](https://github.com/graphql-devise/graphql_devise/tree/b5985036e01ea064e43e457b4f0c8516f172471c/spec/requests) to better understand how to use the gem.
Also, the [dummy app](https://github.com/graphql-devise/graphql_devise/tree/b5985036e01ea064e43e457b4f0c8516f172471c/spec/dummy) used in our specs will give you
a clear idea on how to configure the gem on your Rails application.

### Using Alongside Standard Devise
The DeviseTokenAuth gem allows experimental use of the standard Devise gem to be configured at the same time, for more
information you can check [this answer here](https://github.com/lynndylanhurley/devise_token_auth/blob/2a32f18ccce15638a74e72f6cfde5cf15a808d3f/docs/faq.md#can-i-use-this-gem-alongside-standard-devise).

This gem supports the same and should be easier to handle email templates due to the fact we don't override standard Devise
templates.

## Future Work
We will continue to improve the gem and add better docs.

1. Add install generator.
1. Add mount option that will create a separate schema for the mounted resource.
1. Make sure this gem can correctly work alongside DTA and the original Devise gem.
1. Improve DOCS.
1. Add support for unlockable and other Devise modules.
1. Add feature specs for confirm account and reset password flows.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/graphql-devise/graphql_devise.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
