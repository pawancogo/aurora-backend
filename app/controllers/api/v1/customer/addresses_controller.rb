# frozen_string_literal: true

module Api
  module V1
    module Customer
      # A customer's own saved address book — scoped to current_customer
      # throughout, so touching another customer's address 404s exactly like
      # it not existing (no RBAC permission keys here; those are an
      # admin-only concept, a customer is only ever authorized over their
      # own records).
      class AddressesController < Api::V1::BaseController
        include CustomerAuthentication

        before_action :authenticate_customer!
        before_action :set_address, only: %i[update destroy default]

        # GET /api/v1/customer/addresses
        def index
          addresses = current_customer.addresses.order(is_default: :desc, id: :asc)
          render_success(addresses.map { |address| AddressSerializer.new(address).as_json })
        end

        # POST /api/v1/customer/addresses { address: { ... } }
        def create
          # Checked before .new: building via the association loads its
          # target and appends the unsaved record to it, so calling
          # .none?/.empty? on the same association afterwards would always
          # see that just-built record and never treat this as "the first".
          is_first = current_customer.addresses.none?
          address = current_customer.addresses.new(address_params)
          address.is_default = true if is_first
          address.save!
          render_success(AddressSerializer.new(address).as_json, status: :created)
        end

        # PATCH /api/v1/customer/addresses/:id { address: { ... } }
        def update
          @address.update!(address_params)
          render_success(AddressSerializer.new(@address).as_json)
        end

        # DELETE /api/v1/customer/addresses/:id
        def destroy
          @address.destroy!
          render_success({})
        end

        # PATCH /api/v1/customer/addresses/:id/default
        def default
          @address.update!(is_default: true)
          render_success(AddressSerializer.new(@address).as_json)
        end

        private

        def set_address
          @address = current_customer.addresses.find(params[:id])
        end

        def address_params
          params.require(:address).permit(:address_type, :full_name, :phone, :line1, :line2, :city, :state, :postal_code, :country)
        end
      end
    end
  end
end
