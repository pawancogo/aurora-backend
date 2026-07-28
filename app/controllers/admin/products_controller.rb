# frozen_string_literal: true

module Admin
  class ProductsController < BaseController
    before_action -> { require_permission!("products.read") }, only: :index
    before_action -> { require_permission!("products.manage") }, only: %i[new create edit update destroy]
    before_action :set_product, only: %i[edit update destroy]
    before_action :load_form_options, only: %i[new create edit update]

    def index
      result = Product.search(params, scope: Product.kept.includes(:brand, :category, :product_images).order(created_at: :desc))
      @facets = result.facets
      @products = result.records
    end

    def new
      @product = Product.new(status: :draft, currency: "INR")
      2.times { @product.specifications.build }
    end

    def create
      @product = Product.new(product_params)
      apply_images(@product)
      if @product.save
        redirect_to edit_admin_product_path(@product),
                    notice: "Product “#{@product.name}” created. Add variants, inventory and related products below."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      @product.assign_attributes(product_params)
      apply_images(@product)
      if @product.save
        redirect_to admin_products_path, notice: "Product “#{@product.name}” updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @product.discard!
      redirect_to admin_products_path, notice: "Product archived."
    end

    private

    def set_product
      @product = Product.kept.includes(:product_images).find(params[:id])
    end

    # Brand + category are async typeahead selects (see the form), so only the small
    # tax-class list is preloaded.
    def load_form_options
      @tax_classes = TaxClass.order(:name)
    end

    def product_params
      raw = params.require(:product)
      permitted = raw.permit(
        :name, :slug, :sku, :brand_id, :category_id, :tax_class_id, :status, :currency,
        :featured, :new_arrival, :best_seller, :description, :warranty, :weight_grams,
        :meta_title, :meta_description, :search_keywords, :published_at,
        specifications_attributes: %i[id name value spec_group position _destroy]
      )
      permitted[:price_cents] = to_cents(raw[:price]) if raw.key?(:price)
      permitted[:mrp_cents]   = to_cents(raw[:mrp])   if raw.key?(:mrp)
      if raw.key?(:highlights_text)
        permitted[:highlights] = raw[:highlights_text].to_s.split("\n").map(&:strip).reject(&:blank?)
      end
      if raw.key?(:dimensions)
        dims = raw[:dimensions].permit(:length, :width, :height).to_h
                  .reject { |_, value| value.blank? }.transform_values(&:to_f)
        permitted[:dimensions] = dims
      end
      permitted
    end

    def to_cents(value)
      (value.to_f * 100).round
    end

    # Rebuild the image set from a newline-separated list of URLs (first =
    # primary). A line may append " | <option>" (e.g. "…jpg | Blue") to bind the
    # image to a variant option value, so the storefront swaps to it on select.
    def apply_images(product)
      return unless params.require(:product).key?(:image_urls)

      option_values = bindable_option_values(product)
      product.product_images.destroy_all if product.persisted?
      parse_image_lines(params[:product][:image_urls]).each_with_index do |(url, label), index|
        product.product_images.build(
          source_url: url,
          position: index,
          primary: index.zero?,
          attribute_value: label && option_values[label.downcase]
        )
      end
    end

    # "url" or "url | Blue" → [url, label-or-nil], skipping blank lines.
    def parse_image_lines(raw)
      raw.to_s.split("\n").filter_map do |line|
        url, label = line.split("|", 2).map(&:strip)
        next if url.blank?

        [ url, label.presence ]
      end
    end

    # Downcased value + code → AttributeValue, limited to this product's options.
    def bindable_option_values(product)
      return {} unless product.persisted?

      AttributeValue.joins(:product_variants).where(product_variants: { product_id: product.id }).distinct
                    .each_with_object({}) do |value, acc|
        acc[value.value.downcase] = value
        acc[value.code.downcase] = value
      end
    end
  end
end
