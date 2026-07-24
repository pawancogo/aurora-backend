# frozen_string_literal: true

# The single, reusable uploader for the whole application.
#
# Mount it on any model column:
#     mount_uploader  :file,        GenericUploader
#     mount_uploaders :attachments, GenericUploader   # multiple files
#
# …or use it standalone (see Media::Upload) to store a file and get a URL back.
#
# Storage backend is chosen at boot by StorageProvider (STORAGE_PROVIDER env) —
# this class never needs editing to switch between local disk, S3, or Cloudinary.
#
# Future enhancements (thumbnails, Cloudinary transforms, video processing,
# background/direct uploads) are added here as `version`/`process` blocks or by
# swapping the provider — no change to models, controllers, or services.
class GenericUploader < CarrierWave::Uploader::Base
  if StorageProvider.cloudinary?
    include Cloudinary::CarrierWave # provided once the cloudinary gem is required
  else
    storage StorageProvider.carrierwave_storage # :file (local) or :fog (S3)
  end

  # Every uploadable file category the platform accepts today.
  ALLOWED_EXTENSIONS = %w[
    jpg jpeg png webp gif avif svg
    pdf doc docx txt rtf
    csv xls xlsx ppt pptx
    mp4 webm mov ogg
    mp3 wav aac m4a
    zip
  ].freeze

  # Where files are stored (relative to the storage root). Works whether the
  # uploader is mounted on a record (one dir per record/column) or used standalone
  # (a unique per-upload subdir so files never collide while keeping their original
  # human-friendly filename).
  def store_dir
    if model && mounted_as
      "uploads/#{model.class.name.underscore}/#{mounted_as}/#{model.id}"
    else
      "uploads/media/#{Time.current.utc.strftime('%Y/%m')}/#{upload_token}"
    end
  end

  def extension_allowlist
    ALLOWED_EXTENSIONS
  end

  # Defence-in-depth alongside the extension list: accept whole media categories
  # plus the specific document/archive MIME types (octet-stream covers generic
  # binaries whose type can't be sniffed).
  def content_type_allowlist
    [
      %r{\Aimage/}, %r{\Avideo/}, %r{\Aaudio/},
      "application/pdf", "text/plain", "text/csv", "application/csv",
      "application/vnd.ms-excel",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "application/vnd.ms-powerpoint",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      "application/zip", "application/x-zip-compressed", "application/octet-stream"
    ]
  end

  private

  # Unique subdir for a standalone upload; memoised so cache→store share it.
  def upload_token
    @upload_token ||= SecureRandom.hex(8)
  end
end
