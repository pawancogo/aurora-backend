# frozen_string_literal: true

module Api
  module V1
    module Admin
      class TaxClassesController < Api::V1::BaseController
        include AdminAuthentication

        before_action -> { authorize_permission!("products.read") }, only: %i[index show]
        before_action -> { authorize_permission!("products.manage") }, only: %i[create update destroy]

        def index
          render_success(TaxClass.order(:name).map { |tax_class| TaxClassSerializer.new(tax_class).as_json })
        end

        def show
          render_success(TaxClassSerializer.new(TaxClass.find(params[:id])).as_json)
        end

        def create
          tax_class = TaxClass.create!(tax_class_params)
          render_success(TaxClassSerializer.new(tax_class).as_json, status: :created)
        end

        def update
          tax_class = TaxClass.find(params[:id])
          tax_class.update!(tax_class_params)
          render_success(TaxClassSerializer.new(tax_class).as_json)
        end

        def destroy
          TaxClass.find(params[:id]).destroy!
          render_success({ message: "Tax class deleted." })
        end

        private

        def tax_class_params
          params.require(:tax_class).permit(:name, :rate, :hsn_code)
        end
      end
    end
  end
end
