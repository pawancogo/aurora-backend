# frozen_string_literal: true

# Shared helpers for rendering token responses and capturing request metadata.
module AuthResponses
  extend ActiveSupport::Concern

  private

  def render_token_pair(principal_key, serialized, tokens, status: :ok)
    render_success({
                     principal_key => serialized,
                     tokens: {
                       access_token: tokens.access_token,
                       refresh_token: tokens.refresh_token,
                       token_type: "Bearer",
                       expires_in: tokens.access_expires_in
                     }
                   }, status: status)
  end

  def request_meta
    { user_agent: request.user_agent, ip_address: request.remote_ip }
  end
end
