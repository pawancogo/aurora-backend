# frozen_string_literal: true

# Reads the admin list page-size options from the SiteSetting config model, with
# hard-coded fallbacks so views work even before the settings are seeded.
module PaginationHelper
  FALLBACK_PER_PAGE_OPTIONS = [ 10, 15, 20, 30, 50 ].freeze
  FALLBACK_DEFAULT_PER_PAGE = 10

  def per_page_options
    options = SiteSetting.get("pagination.per_page_options", FALLBACK_PER_PAGE_OPTIONS)
    Array(options).map(&:to_i).select(&:positive?).presence || FALLBACK_PER_PAGE_OPTIONS
  end

  def default_per_page
    SiteSetting.get("pagination.default_per_page", FALLBACK_DEFAULT_PER_PAGE).to_i
  end

  # The page size currently in effect (request param wins over the configured default).
  def current_per_page
    params[:per_page].presence&.to_i&.then { |n| n.positive? ? n : nil } || default_per_page
  end
end
