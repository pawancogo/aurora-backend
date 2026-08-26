# frozen_string_literal: true

module Reviews
  # Recomputes the cached star average, count, and 1–5 distribution on a
  # product from its published reviews. Called after a review is created,
  # published, hidden, or destroyed.
  class RecalculateRatings
    def initialize(product)
      @product = product
    end

    def call
      counts = @product.reviews.published.group(:rating).count
      distribution = (1..5).index_with { |stars| counts[stars].to_i }
      total = distribution.values.sum
      average = if total.zero?
                  0
      else
                  distribution.sum { |stars, count| stars * count }.to_f / total
      end

      @product.update_columns(
        rating_avg: average.round(2),
        rating_count: total,
        rating_distribution: distribution.transform_keys(&:to_s)
      )
    end
  end
end
