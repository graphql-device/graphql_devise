module GraphqlDevise
  module Mutations
    class SignUp < Base
      argument :email,                 String, required: true
      argument :password,              String, required: true
      argument :password_confirmation, String, required: true
      argument :confirm_success_url,   String, required: false

      def resolve(confirm_success_url: nil, **attrs)
        resource = resource_class.new(provider: provider, **attrs)
        raise_user_error(I18n.t('graphql_devise.resource_build_failed')) if resource.blank?

        redirect_url = confirm_success_url || DeviseTokenAuth.default_confirm_success_url
        if confirmable_enabled? && redirect_url.blank?
          raise_user_error(I18n.t('graphql_devise.registrations.missing_confirm_redirect_url'))
        end

        if blacklisted_redirect_url?(redirect_url)
          raise_user_error(I18n.t('graphql_devise.registrations.redirect_url_not_allowed', redirect_url: redirect_url))
        end

        resource.skip_confirmation_notification! if resource.respond_to?(:skip_confirmation_notification!)

        if resource.save
          yield resource if block_given?

          unless resource.confirmed?
            resource.send_confirmation_instructions(
              redirect_url:  confirm_success_url,
              template_path: ['graphql_devise/mailer']
            )
          end

          set_auth_headers(resource) if resource.active_for_authentication?

          { authenticatable: resource }
        else
          clean_up_passwords(resource)
          raise_user_error_list(
            I18n.t('graphql_devise.registration_failed'),
            errors: resource.errors.full_messages
          )
        end
      end

      private

      def provider
        :email
      end

      def clean_up_passwords(resource)
        controller.send(:clean_up_passwords, resource)
      end
    end
  end
end
