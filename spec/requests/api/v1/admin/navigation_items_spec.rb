# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::NavigationItems", type: :request do
  def admin_with(permission_keys)
    role = create(:role)
    permission_keys.each do |key|
      role.permissions << Permission.find_or_create_by!(key: key) { |p| p.name = key }
    end
    admin = create(:admin_user)
    admin.roles << role
    admin
  end

  def auth_header(admin)
    { "Authorization" => "Bearer #{Auth::IssueTokenPair.new(admin).call.access_token}" }
  end

  it "creates an item for an admin with navigation.manage" do
    admin = admin_with(%w[navigation.read navigation.manage])

    post "/api/v1/admin/navigation_items",
         params: { navigation_item: { label: "New", location: "header" } },
         headers: auth_header(admin), as: :json

    expect(response).to have_http_status(:created)
    expect(NavigationItem.find_by(label: "New")).to be_present
  end

  it "forbids create without navigation.manage" do
    admin = admin_with(%w[navigation.read])

    post "/api/v1/admin/navigation_items",
         params: { navigation_item: { label: "Nope", location: "header" } },
         headers: auth_header(admin), as: :json

    expect(response).to have_http_status(:forbidden)
    expect(NavigationItem.find_by(label: "Nope")).to be_nil
  end

  it "reorders items" do
    admin = admin_with(%w[navigation.read navigation.manage])
    item = create(:navigation_item, position: 1)

    post "/api/v1/admin/navigation_items/reorder",
         params: { items: [ { id: item.id, parent_id: nil, position: 5 } ] },
         headers: auth_header(admin), as: :json

    expect(response).to have_http_status(:ok)
    expect(item.reload.position).to eq(5)
  end

  it "requires authentication" do
    post "/api/v1/admin/navigation_items",
         params: { navigation_item: { label: "X", location: "header" } }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
