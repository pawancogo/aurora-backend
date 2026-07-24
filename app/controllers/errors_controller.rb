# frozen_string_literal: true

# Catches unmatched routes and returns the standard JSON 404 envelope
# instead of Rails' default HTML error page.
class ErrorsController < ActionController::API
  include ApiResponders

  def not_found
    render_error(code: "not_found", message: "The requested resource was not found.", status: :not_found)
  end
end
