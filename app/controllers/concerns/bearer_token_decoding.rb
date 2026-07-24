# frozen_string_literal: true

# Extracts and decodes a Bearer access token from the Authorization header.
module BearerTokenDecoding
  extend ActiveSupport::Concern

  private

  def decoded_token
    return @decoded_token if defined?(@decoded_token)

    header = request.headers["Authorization"].to_s
    raw = header.start_with?("Bearer ") ? header.split(" ", 2).last : nil
    @decoded_token = raw.present? ? JsonWebToken.decode(raw) : nil
  rescue JsonWebToken::DecodeError
    @decoded_token = nil
  end
end
