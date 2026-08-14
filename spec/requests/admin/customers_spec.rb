# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin customers", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "lists customers for an admin with customers.read" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    create(:customer, email: "shown@example.com")

    get "/admin/customers"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("shown@example.com")
  end

  it "shows a customer with their login sessions" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    customer = create(:customer)
    Auth::IssueTokenPair.new(customer).call

    get "/admin/customers/#{customer.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Login sessions")
  end

  it "shows a customer's saved addresses, read-only" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    customer = create(:customer)
    create(:address, customer: customer, full_name: "Jane Doe", is_default: true)

    get "/admin/customers/#{customer.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Jane Doe")
    expect(response.body).to include("Default")
  end

  it "edits a customer's contact details" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    customer = create(:customer)

    patch "/admin/customers/#{customer.id}",
          params: { customer: { first_name: "Ada", last_name: "Lovelace", phone: "+91 90000 00000" } }

    customer.reload
    expect(customer.first_name).to eq("Ada")
    expect(customer.phone).to eq("+91 90000 00000")
    expect(response).to redirect_to("/admin/customers/#{customer.id}")
  end

  it "toggles a customer's status" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    customer = create(:customer)

    patch "/admin/customers/#{customer.id}/status"

    expect(customer.reload.status).to eq("inactive")
  end

  it "revokes a single session" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    customer = create(:customer)
    Auth::IssueTokenPair.new(customer).call
    session = customer.refresh_tokens.first

    delete "/admin/customers/#{customer.id}/sessions/#{session.id}"

    expect(session.reload.revoked_at).to be_present
  end

  it "revokes all active sessions" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    customer = create(:customer)
    Auth::IssueTokenPair.new(customer).call

    delete "/admin/customers/#{customer.id}/sessions"

    expect(customer.refresh_tokens.active.count).to eq(0)
  end

  it "forbids access without customers.read" do
    sign_in_admin(create(:admin_user, password: "password1234"))

    get "/admin/customers"

    expect(response).to redirect_to("/admin")
  end
end
