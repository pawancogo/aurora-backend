# frozen_string_literal: true

require "rails_helper"

RSpec.describe Media::Upload do
  def uploaded(content_type)
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/pixel.png"), content_type)
  end

  it "stores an image via CarrierWave and returns an uploader with a URL" do
    uploader = described_class.new(uploaded("image/png"), kind: :image).call

    expect(uploader).to be_a(GenericUploader)
    expect(uploader.url).to match(%r{/uploads/media/.+\.png\z})
    expect(uploader.file.content_type).to eq("image/png")
  end

  it "rejects a file whose type doesn't match the requested kind" do
    expect { described_class.new(uploaded("text/plain"), kind: :image).call }
      .to raise_error(described_class::InvalidUpload, /Unsupported/)
  end

  it "rejects a file over the size cap" do
    oversized = instance_double(ActionDispatch::Http::UploadedFile, content_type: "image/png", size: 11.megabytes)
    expect { described_class.new(oversized, kind: :image).call }
      .to raise_error(described_class::InvalidUpload, /too large/)
  end

  it "accepts an upload declared as video under the video kind" do
    uploader = described_class.new(uploaded("video/mp4"), kind: :video).call
    expect(uploader.url).to be_present
  end
end
