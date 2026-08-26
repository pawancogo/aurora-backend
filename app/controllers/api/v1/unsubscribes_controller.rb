# frozen_string_literal: true

module Api
  module V1
    # Public one-click unsubscribe for optional (non-transactional) email.
    # GET is read-only so email-client prefetch cannot opt someone out.
    class UnsubscribesController < BaseController
      # GET /api/v1/unsubscribe?token=
      def show
        customer = find_customer!
        render_success({
          email: masked_email(customer.email),
          email_marketing: customer.email_marketing?
        })
      end

      # POST /api/v1/unsubscribe  { token: "..." }
      def create
        customer = find_customer!
        customer.update!(email_marketing: false)
        render_success({
          email: masked_email(customer.email),
          email_marketing: false
        })
      end

      private

      def find_customer!
        token = params[:token].to_s
        raise ActiveRecord::RecordNotFound if token.blank?

        ::Customer.kept.find_by!(unsubscribe_token: token)
      end

      def masked_email(email)
        local, domain = email.to_s.split("@", 2)
        return email if local.blank? || domain.blank?

        visible = local[0]
        "#{visible}#{'*' * [ local.length - 1, 1 ].max}@#{domain}"
      end
    end
  end
end
