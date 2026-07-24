# frozen_string_literal: true

# Kaminari-based pagination helper producing a standard meta payload.
# Not exercised until listing endpoints arrive (Sprint 4+), but establishes the pattern.
module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 10
  MAX_PER_PAGE = 100

  def paginate(scope)
    paginated = scope.page(current_page).per(current_per_page)
    [ paginated, pagination_meta(paginated) ]
  end

  private

  def current_page
    params[:page].presence || 1
  end

  def current_per_page
    requested = (params[:per_page].presence || DEFAULT_PER_PAGE).to_i
    return DEFAULT_PER_PAGE if requested <= 0

    [ requested, MAX_PER_PAGE ].min
  end

  def pagination_meta(relation)
    {
      current_page: relation.current_page,
      per_page: relation.limit_value,
      total_pages: relation.total_pages,
      total_count: relation.total_count
    }
  end
end
