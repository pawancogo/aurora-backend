# frozen_string_literal: true

module Catalog
  # Builds a nested category tree from a single query (no N+1).
  class CategoryTree
    def initialize(scope: :public)
      @scope = scope
    end

    def as_json
      build(nil)
    end

    private

    def items
      @items ||= begin
        relation = @scope == :public ? Category.kept.visible : Category.kept
        relation.ordered.to_a
      end
    end

    def build(parent_id)
      items
        .select { |category| category.parent_id == parent_id }
        .map { |category| CategorySerializer.new(category, children: build(category.id)).as_json }
    end
  end
end
