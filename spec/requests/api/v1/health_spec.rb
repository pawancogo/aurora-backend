# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Health", type: :request do
  describe "GET /api/v1/health" do
    it "returns an ok liveness envelope" do
      get "/api/v1/health"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["data"]).to include(
        "status" => "ok",
        "service" => "api",
        "version" => API_VERSION
      )
    end
  end

  describe "GET /api/v1/ready" do
    it "returns 200 and 'ready' when all dependencies are healthy" do
      get "/api/v1/ready"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["data"]["status"]).to eq("ready")
      expect(body["data"]["dependencies"]).to include("database" => "ok", "redis" => "ok")
    end

    it "returns 503 and 'not_ready' when a dependency is down" do
      down_result = Health::ReadinessCheck::Result.new({ "database" => "ok", "redis" => "down" })
      allow_any_instance_of(Health::ReadinessCheck).to receive(:call).and_return(down_result)

      get "/api/v1/ready"

      expect(response).to have_http_status(:service_unavailable)
      body = response.parsed_body
      expect(body["data"]["status"]).to eq("not_ready")
      expect(body["data"]["dependencies"]["redis"]).to eq("down")
    end
  end
end
