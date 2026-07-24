# frozen_string_literal: true

module Health
  # Verifies that critical infrastructure dependencies are reachable.
  # Returns a Result reporting each dependency's status ("ok" / "down").
  class ReadinessCheck
    Result = Struct.new(:dependencies) do
      def ready?
        dependencies.values.all? { |status| status == "ok" }
      end
    end

    def call
      Result.new({
                   "database" => database_status,
                   "redis" => redis_status
                 })
    end

    private

    def database_status
      ActiveRecord::Base.connection.execute("SELECT 1")
      "ok"
    rescue StandardError => e
      Rails.logger.warn("[ReadinessCheck] database check failed: #{e.message}")
      "down"
    end

    def redis_status
      REDIS_POOL.with { |redis| redis.ping } == "PONG" ? "ok" : "down"
    rescue StandardError => e
      Rails.logger.warn("[ReadinessCheck] redis check failed: #{e.message}")
      "down"
    end
  end
end
