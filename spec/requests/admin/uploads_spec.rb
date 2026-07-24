# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin media uploads", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  def file(content_type)
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/pixel.png"), content_type)
  end

  it "stores a file and returns an absolute URL" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))

    post "/admin/uploads", params: { file: file("image/png"), kind: "image" }

    expect(response).to have_http_status(:created)
    body = response.parsed_body
    expect(body["url"]).to match(%r{\Ahttp.+/uploads/media/.+\.png\z})
    expect(body["content_type"]).to eq("image/png")
    expect(body["byte_size"]).to be > 0
  end

  it "rejects a non-image under the image kind" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))

    post "/admin/uploads", params: { file: file("text/plain"), kind: "image" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]).to be_present
  end

  it "requires authentication" do
    post "/admin/uploads", params: { file: file("image/png") }
    expect(response).to redirect_to("/admin/login")
  end
end
