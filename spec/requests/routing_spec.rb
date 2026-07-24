# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Routing fallbacks", type: :request do
  it "returns a JSON 404 envelope for unknown routes" do
    get "/api/v1/this-does-not-exist"

    expect(response).to have_http_status(:not_found)
    body = response.parsed_body
    expect(body["error"]).to include("code" => "not_found")
    expect(body["error"]["message"]).to be_present
  end
end
