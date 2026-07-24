# frozen_string_literal: true

module Admin
  # Generic upload endpoint backing the reusable admin uploader widget. Accepts a
  # file + kind (image|video), stores it via Media::Upload (CarrierWave), and
  # returns its URL. Provider-agnostic — the same response shape whether the file
  # landed on local disk, S3, or Cloudinary.
  class UploadsController < BaseController
    def create
      uploader = Media::Upload.new(params[:file], kind: params[:kind].presence || :image).call
      render json: {
        url: absolute_url(uploader.url),
        filename: uploader.file.filename,
        content_type: uploader.file.content_type,
        byte_size: uploader.file.size
      }, status: :created
    rescue Media::Upload::InvalidUpload => e
      render json: { error: e.message }, status: :unprocessable_content
    end

    private

    # Local disk returns a root-relative path ("/uploads/…"); make it absolute so
    # the storefront (different origin) can load it. S3/Cloudinary already return
    # absolute URLs.
    def absolute_url(url)
      url.to_s.start_with?("http") ? url : "#{request.base_url}#{url}"
    end
  end
end
