# frozen_string_literal: true

module Admin
  # Adds/removes related-product links from the product edit page.
  class ProductRelationsController < BaseController
    before_action -> { require_permission!("products.manage") }
    before_action :set_product

    def create
      relation = @product.product_relations.build(
        related_product_id: params[:related_product_id],
        relation_kind: params[:relation_kind].presence || "related"
      )
      if relation.save
        redirect_to edit_admin_product_path(@product, anchor: "related"), notice: "Related product added."
      else
        redirect_to edit_admin_product_path(@product, anchor: "related"),
                    alert: relation.errors.full_messages.to_sentence.presence || "Couldn't add related product."
      end
    end

    def destroy
      @product.product_relations.find(params[:id]).destroy
      redirect_to edit_admin_product_path(@product, anchor: "related"), notice: "Related product removed."
    end

    private

    def set_product
      @product = Product.kept.find(params[:product_id])
    end
  end
end
