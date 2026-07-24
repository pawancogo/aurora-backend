# frozen_string_literal: true

module Admin
  # Customer management: list, detail, activate/deactivate, and login-session control.
  class CustomersController < BaseController
    before_action -> { require_permission!("customers.read") }, only: %i[index show]
    before_action -> { require_permission!("customers.manage") },
                  only: %i[edit update update_status revoke_sessions revoke_session]
    before_action :set_customer, only: %i[show edit update update_status revoke_sessions revoke_session]

    def index
      result = Customer.search(params, scope: Customer.kept.order(created_at: :desc))
      @facets = result.facets
      @customers = result.records
    end

    def show
      @sessions = @customer.refresh_tokens.order(created_at: :desc).limit(50)
    end

    def edit; end

    def update
      if @customer.update(customer_params)
        redirect_to admin_customer_path(@customer), notice: "Customer details updated."
      else
        @sessions = @customer.refresh_tokens.order(created_at: :desc).limit(50)
        render :edit, status: :unprocessable_content
      end
    end

    def update_status
      new_status = @customer.status == "active" ? "inactive" : "active"
      @customer.update!(status: new_status)
      redirect_to admin_customer_path(@customer), notice: "Customer marked #{new_status}."
    end

    def revoke_sessions
      count = @customer.refresh_tokens.active.update_all(revoked_at: Time.current)
      redirect_to admin_customer_path(@customer), notice: "Revoked #{count} active session(s)."
    end

    def revoke_session
      @customer.refresh_tokens.find(params[:token_id]).revoke!
      redirect_to admin_customer_path(@customer), notice: "Session revoked."
    end

    private

    def set_customer
      @customer = Customer.kept.find(params[:id])
    end

    def customer_params
      params.require(:customer).permit(:first_name, :last_name, :phone)
    end
  end
end
