# frozen_string_literal: true

module Navigation
  # Redis-backed cache for the public navigation tree. Bypassed in test for
  # deterministic specs; busted automatically on any NavigationItem change.
  class TreeCache
    TTL_SECONDS = 3600
    LOCATIONS = %w[header footer].freeze

    class << self
      def fetch(location)
        return build(location) if Rails.env.test?

        cached = REDIS_POOL.with { |redis| redis.get(cache_key(location)) }
        return JSON.parse(cached) if cached

        build(location).tap do |tree|
          REDIS_POOL.with { |redis| redis.set(cache_key(location), tree.to_json, ex: TTL_SECONDS) }
        end
      end

      def clear!
        REDIS_POOL.with do |redis|
          LOCATIONS.each { |location| redis.del(cache_key(location)) }
        end
      rescue StandardError => e
        Rails.logger.warn("[Navigation::TreeCache] clear failed: #{e.message}")
      end

      private

      def build(location)
        TreeBuilder.new(location: location, scope: :public).as_json
      end

      def cache_key(location)
        "navigation:tree:#{location}"
      end
    end
  end
end
