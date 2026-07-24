# frozen_string_literal: true

require "rails_helper"

RSpec.describe Health::ReadinessCheck do
  subject(:result) { described_class.new.call }

  context "when all dependencies are reachable" do
    it "reports ready with every dependency ok" do
      expect(result).to be_ready
      expect(result.dependencies).to eq({ "database" => "ok", "redis" => "ok" })
    end
  end

  context "when Redis is unreachable" do
    before do
      pool = instance_double(ConnectionPool)
      allow(pool).to receive(:with).and_raise(Redis::CannotConnectError.new("connection refused"))
      stub_const("REDIS_POOL", pool)
    end

    it "reports not ready and marks redis down" do
      expect(result).not_to be_ready
      expect(result.dependencies["redis"]).to eq("down")
      expect(result.dependencies["database"]).to eq("ok")
    end
  end
end
