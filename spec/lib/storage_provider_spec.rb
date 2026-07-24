# frozen_string_literal: true

require "rails_helper"

# StorageProvider is loaded at boot by config/initializers/carrierwave.rb.
RSpec.describe StorageProvider do
  around do |example|
    original = ENV["STORAGE_PROVIDER"]
    example.run
    ENV["STORAGE_PROVIDER"] = original
  end

  it "defaults to local" do
    ENV.delete("STORAGE_PROVIDER")
    expect(described_class.current).to eq("local")
    expect(described_class.local?).to be(true)
    expect(described_class.carrierwave_storage).to eq(:file)
  end

  it "selects AWS (fog storage)" do
    ENV["STORAGE_PROVIDER"] = "aws"
    expect(described_class.aws?).to be(true)
    expect(described_class.carrierwave_storage).to eq(:fog)
  end

  it "selects Cloudinary" do
    ENV["STORAGE_PROVIDER"] = "cloudinary"
    expect(described_class.cloudinary?).to be(true)
  end

  it "falls back to local for an unknown provider" do
    ENV["STORAGE_PROVIDER"] = "ftp"
    expect(described_class.current).to eq("local")
  end
end
