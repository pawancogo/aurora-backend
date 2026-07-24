# frozen_string_literal: true

module Api
  module V1
    class HealthController < BaseController
      # GET /api/v1/health — liveness. Cheap, no dependency checks.
      def show
        render_success({
                         status: "ok",
                         service: "api",
                         version: API_VERSION,
                         time: Time.current.iso8601
                       })
      end

      # GET /api/v1/ready — readiness. Verifies DB + Redis; 503 if any dependency is down.
      def ready
        result = Health::ReadinessCheck.new.call
        http_status = result.ready? ? :ok : :service_unavailable

        render_success({
                         status: result.ready? ? "ready" : "not_ready",
                         dependencies: result.dependencies
                       }, status: http_status)
      end
    end
  end
end
