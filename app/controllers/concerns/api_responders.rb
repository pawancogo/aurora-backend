# frozen_string_literal: true

# Standard success/error JSON envelope helpers shared by all API controllers.
#
#   success => { "data": {...}, "meta": {...}? }
#   error   => { "error": { "code": "...", "message": "...", "details": {} } }
module ApiResponders
  extend ActiveSupport::Concern

  def render_success(data = nil, meta: nil, status: :ok)
    payload = { data: data }
    payload[:meta] = meta unless meta.nil?
    render json: payload, status: status
  end

  def render_error(code:, message:, details: {}, status: :unprocessable_content)
    render json: { error: { code: code, message: message, details: details } }, status: status
  end
end
