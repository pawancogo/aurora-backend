# frozen_string_literal: true

require_relative "../storage_provider"

# Configures CarrierWave for the provider selected by STORAGE_PROVIDER. Only the
# chosen provider's gem is required, so the default (local) adds no boot cost and
# fog-aws / cloudinary stay dormant until switched on. Credentials come from ENV
# first, then Rails encrypted credentials — never hard-coded.
CarrierWave.configure do |config|
  # Incoming uploads are cached here before being moved to the final store.
  config.cache_dir = Rails.root.join("tmp/uploads")

  case StorageProvider.current
  when StorageProvider::AWS
    require "fog/aws"
    config.storage = :fog
    config.fog_provider = "fog/aws"
    config.fog_credentials = {
      provider: "AWS",
      aws_access_key_id: ENV["AWS_ACCESS_KEY_ID"] || Rails.application.credentials.dig(:aws, :access_key_id),
      aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"] || Rails.application.credentials.dig(:aws, :secret_access_key),
      region: ENV.fetch("AWS_REGION", "us-east-1")
    }
    config.fog_directory = ENV["AWS_BUCKET"] || Rails.application.credentials.dig(:aws, :bucket)
    config.fog_public = ActiveModel::Type::Boolean.new.cast(ENV.fetch("AWS_PUBLIC", "true"))
    config.asset_host = ENV["ASSET_HOST"].presence

  when StorageProvider::CLOUDINARY
    require "cloudinary"
    # The cloudinary gem reads CLOUDINARY_URL (or config/cloudinary.yml) for creds
    # and provides Cloudinary::CarrierWave, which GenericUploader includes. Uploads
    # are still cached to local disk first.
    config.cache_storage = :file

  else # local (default) — disk under public/uploads
    config.storage = :file
    config.asset_host = ENV["ASSET_HOST"].presence
  end
end
