# frozen_string_literal: true

module Api
  module V1
    module Customer
      # Storefront address book. Signed-in customers manage only their own
      # saved addresses (scoped via current_customer — never a global find).
      class AddressesController < Api::V1::BaseController
        include CustomerAuthentication

        before_action :authenticate_customer!
        before_action :set_address, only: %i[update destroy default]

        # GET /api/v1/customer/addresses
        def index
          render_success(AddressSerializer.collection(addresses))
        end

        # POST /api/v1/customer/addresses  { address: { ... } }
        def create
          address = current_customer.addresses.create!(address_params)
          render_success(AddressSerializer.new(address).as_json, status: :created)
        end

        # PATCH /api/v1/customer/addresses/:id  { address: { ... } }
        def update
          @address.update!(address_params)
          render_success(AddressSerializer.new(@address).as_json)
        end

        # DELETE /api/v1/customer/addresses/:id
        def destroy
          @address.destroy!
          render_success({ id: @address.id })
        end

        # PATCH /api/v1/customer/addresses/:id/default
        def default
          @address.make_default!
          render_success(AddressSerializer.new(@address.reload).as_json)
        end

        private

        def addresses
          current_customer.addresses.order(is_default: :desc, id: :asc)
        end

        def set_address
          @address = current_customer.addresses.find(params[:id])
        end

        def address_params
          permitted = params.require(:address).permit(
            :address_type, :full_name, :phone, :line1, :line2,
            :city, :state, :postal_code, :country
          )
          permitted[:line2] = permitted[:line2].presence if permitted.key?(:line2)
          permitted
        end
      end
    end
  end
end
