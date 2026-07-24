# frozen_string_literal: true

# Keep test uploads out of public/ and clean them up after the suite.
CarrierWave.configure do |config|
  config.root = Rails.root.join("tmp/test_uploads")
  config.cache_dir = Rails.root.join("tmp/test_uploads/cache")
  config.storage = :file
  config.enable_processing = false
end

RSpec.configure do |config|
  config.after(:suite) { FileUtils.rm_rf(Rails.root.join("tmp/test_uploads")) }
end
