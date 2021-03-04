# frozen_string_literal: true

module Mutations
  module User
    class Update < Types::Mutation
      graphql_name 'UserUpdate'

      argument :uuid, ID, required: true
      argument :email, String, required: false
      argument :name, String, required: false
      argument :locale, String, required: false

      field :user, Objects::User, null: true
      field :token, String, null: true

      def authorized?(**args)
        raise unauthorised_error unless logged_in?
        raise not_found_error('User Not Found') unless user(**args)
        raise forbidden_error unless policy.update?

        true
      end

      def resolve(**args)
        if @user.update(args.except(:uuid))
          token = generate_jwt(@user, session)
          trigger(:user_updated, { uuid: @user.uuid }, @user)
          { user: @user, token: token }
        else
          errors = @user.errors.full_messages
          unprocessable_error(errors.join(', '))
        end
      end

      private

      def user(**args)
        @user ||= ::User.find_by_uuid(args[:uuid])
      end

      def policy
        UserPolicy.new(current_user, @user)
      end
    end
  end
end
