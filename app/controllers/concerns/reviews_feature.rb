# frozen_string_literal: true

# Gates review/Q&A endpoints on the seeded `reviews` feature flag.
module ReviewsFeature
  extend ActiveSupport::Concern

  private

  def require_reviews_enabled!
    return if FeatureFlag.enabled?("reviews")

    render_error(code: "reviews_disabled", message: "Product reviews are turned off.", status: :not_found)
  end

  def find_live_product!
    Product.kept.live.find_by!(slug: params[:product_id])
  end
end
