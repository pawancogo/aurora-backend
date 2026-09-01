# frozen_string_literal: true

module Admin
  # Customer management: list, detail, activate/deactivate (block), notes, and login-session control.
  class CustomersController < BaseController
    before_action -> { require_permission!("customers.read") }, only: %i[index show export]
    before_action -> { require_permission!("customers.manage") },
                  only: %i[edit update update_status revoke_sessions revoke_session create_note]
    before_action :set_customer, only: %i[show edit update update_status revoke_sessions revoke_session create_note]

    def index
      result = Customer.search(params, scope: Customer.kept.order(created_at: :desc))
      @facets = result.facets
      @customers = result.records
    end

    def export
      result = Customer.search(params, scope: Customer.kept.order(created_at: :desc), paginate: false)
      send_csv("customers", %w[id email first_name last_name phone status verified joined_at]) do |csv|
        result.records.limit(EXPORT_LIMIT).each do |customer|
          csv << [
            customer.id, customer.email, customer.first_name, customer.last_name,
            customer.phone, customer.status, customer.confirmed?, customer.created_at&.iso8601
          ]
        end
      end
    end

    def show
      @sessions = @customer.refresh_tokens.order(created_at: :desc).limit(50)
      @addresses = @customer.addresses.order(is_default: :desc, id: :asc)
      @notes = @customer.customer_notes.recent.includes(:admin_user)
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
      if @customer.status == "active"
        @customer.update!(status: "inactive")
        revoked = @customer.refresh_tokens.active.update_all(revoked_at: Time.current)
        redirect_to admin_customer_path(@customer),
                    notice: "Customer blocked. Revoked #{revoked} active session(s)."
      else
        @customer.update!(status: "active")
        redirect_to admin_customer_path(@customer), notice: "Customer unblocked."
      end
    end

    def create_note
      note = @customer.customer_notes.build(body: params[:body], admin_user: current_admin_user)
      if note.save
        redirect_to admin_customer_path(@customer), notice: "Note added."
      else
        redirect_to admin_customer_path(@customer), alert: note.errors.full_messages.to_sentence
      end
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
