# frozen_string_literal: true

# Trivial job that proves the ActiveJob -> Sidekiq -> Redis pipeline is wired correctly.
class HealthPingJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("[HealthPingJob] pong at #{Time.current.iso8601}")
  end
end
