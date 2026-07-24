# frozen_string_literal: true

module Navigation
  # Builds a nested (unlimited-depth) navigation tree from a single flat query,
  # assembling children in memory to avoid N+1. `scope: :public` filters to
  # visible + currently-scheduled items; `:admin` returns everything.
  class TreeBuilder
    def initialize(location: "header", scope: :public)
      @location = location
      @scope = scope
    end

    def as_json
      build(nil)
    end

    private

    def items
      @items ||= begin
        relation = NavigationItem.for_location(@location).ordered
        relation = relation.visible.live if @scope == :public
        relation.to_a
      end
    end

    def build(parent_id)
      items
        .select { |item| item.parent_id == parent_id }
        .map { |item| NavigationItemSerializer.new(item, children: build(item.id)).as_json }
    end
  end
end
