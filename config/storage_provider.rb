# frozen_string_literal: true

# Single source of truth for the active file-storage backend.
#
# The provider is chosen ONLY via the STORAGE_PROVIDER env var — no code change
# is ever needed to switch:
#
#   STORAGE_PROVIDER=local       # default: disk under public/uploads (dev/test)
#   STORAGE_PROVIDER=aws         # AWS S3 via fog (production)
#   STORAGE_PROVIDER=cloudinary  # Cloudinary (media-heavy: images/video)
#
# Consumed by config/initializers/carrierwave.rb (backend config + credentials)
# and GenericUploader (which storage engine / Cloudinary include to use).
#
# Lives in config/ (not lib/) so it loads once at boot via require_relative and
# is never touched by the autoloader/reloader — safe to reference during init.
module StorageProvider
  LOCAL = "local"
  AWS = "aws"
  CLOUDINARY = "cloudinary"
  SUPPORTED = [ LOCAL, AWS, CLOUDINARY ].freeze

  module_function

  # The selected provider, falling back to :local for any unknown value.
  def current
    value = ENV.fetch("STORAGE_PROVIDER", LOCAL).to_s.strip.downcase
    SUPPORTED.include?(value) ? value : LOCAL
  end

  def local?      = current == LOCAL
  def aws?        = current == AWS
  def cloudinary? = current == CLOUDINARY

  # CarrierWave storage engine for the file-based providers. Cloudinary is wired
  # instead by `include Cloudinary::CarrierWave` in the uploader.
  def carrierwave_storage
    aws? ? :fog : :file
  end
end
