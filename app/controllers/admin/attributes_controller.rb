# frozen_string_literal: true

module Admin
  # Manages the attribute registry (option types like Color/Size and their values).
  # Attributes are catalog metadata, so they reuse the products.* permissions.
  class AttributesController < BaseController
    before_action -> { require_permission!("products.read") }, only: :index
    before_action -> { require_permission!("products.manage") }, only: %i[new create edit update destroy]
    before_action :set_attribute, only: %i[edit update destroy]

    def index
      result = ProductAttribute.search(params, scope: ProductAttribute.includes(:attribute_values).ordered)
      @facets = result.facets
      @attributes = result.records
    end

    def new
      @attribute = ProductAttribute.new
      3.times { @attribute.attribute_values.build }
    end

    def create
      @attribute = ProductAttribute.new(attribute_params)
      if @attribute.save
        redirect_to admin_attributes_path, notice: "Attribute “#{@attribute.name}” created."
      else
        @attribute.attribute_values.build if @attribute.attribute_values.empty?
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @attribute.attribute_values.build
    end

    def update
      if @attribute.update(attribute_params)
        redirect_to admin_attributes_path, notice: "Attribute “#{@attribute.name}” updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @attribute.attribute_values.joins(:variant_option_values).exists?
        redirect_to admin_attributes_path, alert: "Can't delete “#{@attribute.name}” — some of its values are used by variants."
      else
        @attribute.destroy
        redirect_to admin_attributes_path, notice: "Attribute deleted."
      end
    end

    private

    def set_attribute
      @attribute = ProductAttribute.includes(:attribute_values).find(params[:id])
    end

    def attribute_params
      params.require(:product_attribute).permit(
        :name, :code, :filterable, :searchable, :position,
        attribute_values_attributes: %i[id value code position _destroy]
      )
    end
  end
end
