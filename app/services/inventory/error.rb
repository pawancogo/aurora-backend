# frozen_string_literal: true

module Inventory
  # Raised when an inventory operation violates a business rule (e.g. overselling).
  # Column-level guarantees are enforced by model validations; this covers the
  # service-level rules.
  class Error < StandardError; end
end
