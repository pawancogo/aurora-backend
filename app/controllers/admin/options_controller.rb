# frozen_string_literal: true

module Admin
  # Typeahead source for async custom-select dropdowns. Returns at most 20 matches
  # so a picker over millions of rows never loads them all — the client fetches as
  # the user types. Each resource maps to a SearchManager-enabled model + read gate.
  class OptionsController < BaseController
    PER_PAGE = 20

    RESOURCES = {
      "brands"     => { model: Brand,    permission: "brands.read" },
      "categories" => { model: Category, permission: "categories.read" },
      "products"   => { model: Product,  permission: "products.read" }
    }.freeze

    def index
      config = RESOURCES[params[:resource]]
      return render(json: { data: [] }, status: :not_found) unless config
      return render(json: { data: [] }, status: :forbidden) unless allowed_to?(config[:permission])

      records = lookup(config[:model])
      render json: {
        data: records.map { |record| { value: record.id, label: option_label(record) } },
        meta: { next_page: records.next_page } # drives the dropdown's infinite scroll
      }
    end

    private

    def lookup(model)
      scope = model.respond_to?(:kept) ? model.kept : model.all
      scope = scope.where.not(id: params[:exclude]) if params[:exclude].present?
      model.search({ q: params[:q], page: params[:page], per_page: PER_PAGE }, scope: scope).records
    end

    def option_label(record)
      record.try(:name) || record.try(:title) || record.to_s
    end
  end
end
