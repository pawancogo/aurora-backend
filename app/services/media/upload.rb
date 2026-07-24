# frozen_string_literal: true

module Media
  # Stores a single uploaded file via GenericUploader (standalone) and returns the
  # uploader, from which the caller reads `.url` / `.file`. Used by the admin media
  # endpoint, so it additionally restricts the file to the requested `kind`
  # (image|video) with a size cap; GenericUploader's own allowlists are the
  # broader guard for files mounted on models.
  #
  # Storage backend is whatever StorageProvider selects — this service is
  # provider-agnostic.
  class Upload
    class InvalidUpload < StandardError; end

    KIND_PATTERNS = { image: %r{\Aimage/}, video: %r{\Avideo/} }.freeze
    MAX_BYTES = { image: 10.megabytes, video: 200.megabytes }.freeze

    def initialize(file, kind: :image)
      @file = file
      @kind = KIND_PATTERNS.key?(kind.to_sym) ? kind.to_sym : :image
    end

    def call
      validate!

      uploader = GenericUploader.new
      uploader.store!(@file)
      uploader
    rescue CarrierWave::IntegrityError, CarrierWave::ProcessingError => e
      raise InvalidUpload, e.message
    end

    private

    def validate!
      raise InvalidUpload, "No file provided." unless @file.respond_to?(:content_type) && @file.respond_to?(:size)
      raise InvalidUpload, "Unsupported #{@kind} type." unless @file.content_type.to_s.match?(KIND_PATTERNS[@kind])
      return unless @file.size.to_i > MAX_BYTES[@kind]

      raise InvalidUpload, "File is too large (max #{MAX_BYTES[@kind] / 1.megabyte} MB)."
    end
  end
end
