# frozen_string_literal: true

# Centralized rescue handlers translating exceptions into the error envelope.
# Handlers are declared generic-first so the most specific match wins at runtime.
module ApiErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_internal_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
  end

  private

  def handle_not_found(error)
    render_error(code: "not_found", message: error.message, status: :not_found)
  end

  def handle_parameter_missing(error)
    render_error(code: "parameter_missing", message: error.message, status: :bad_request)
  end

  def handle_record_invalid(error)
    render_error(
      code: "validation_failed",
      message: "Validation failed.",
      details: error.record.errors.to_hash(true),
      status: :unprocessable_content
    )
  end

  def handle_internal_error(error)
    Rails.logger.error("[#{error.class}] #{error.message}\n#{Array(error.backtrace).first(10).join("\n")}")
    # Surface the real error while developing/testing; hide details in production.
    raise error unless Rails.env.production?

    render_error(code: "internal_error", message: "Something went wrong. Please try again later.",
                 status: :internal_server_error)
  end
end
