# frozen_string_literal: true

# Generic, declarative search + filter engine for a model.
#
#   class Product < ApplicationRecord
#     include SearchManager
#     search_manager on: %i[name sku], aggs_on: %i[status brand_id featured], range_on: :price_cents
#   end
#
#   result = Product.search(params, scope: Product.kept)
#   result.records   # filtered relation (caller paginates/orders)
#   result.facets    # { "status" => [{ value:, label:, count: }, ...], ... }
#
# - `on`       : columns matched (ILIKE) against the free-text `q` param.
# - `aggs_on`  : columns exposed as multi-value filters *and* faceted counts.
# - `range_on` : numeric column filtered by the `min` / `max` params.
#
# Facets are disjunctive: each facet's counts reflect every *other* active
# filter but not its own, so selecting one option still shows the alternatives.
# All conditions are built with Arel/hash forms (no string interpolation).
module SearchManager
  extend ActiveSupport::Concern

  Result = Struct.new(:records, :facets, keyword_init: true)

  # Cap facet options so a high-cardinality column (hundreds of brands/categories)
  # can't produce an unusable dropdown. Overridable per model via `facet_limit:`.
  DEFAULT_FACET_LIMIT = 20

  # Pagination defaults (params: `page`, `per_page`). Overridable per model via `per_page:`.
  DEFAULT_PER_PAGE = 10
  MAX_PER_PAGE = 100

  class_methods do
    def search_manager(on:, aggs_on: [], range_on: nil, search_key: :q, facet_limit: nil, per_page: nil)
      @search_on = Array(on).map(&:to_sym)
      @search_aggs_on = Array(aggs_on).map(&:to_sym)
      @search_range_on = range_on&.to_sym
      @search_key = search_key.to_sym
      @search_facet_limit = facet_limit
      @search_per_page = per_page
    end

    def search_config
      {
        on: @search_on || [],
        aggs_on: @search_aggs_on || [],
        range_on: @search_range_on,
        search_key: @search_key || :q,
        facet_limit: @search_facet_limit || DEFAULT_FACET_LIMIT,
        per_page: @search_per_page || DEFAULT_PER_PAGE
      }
    end

    # Returns Result(records:, facets:). `records` is paginated (Kaminari) unless
    # `paginate: false` — pass an ordered scope; ordering is preserved through paging.
    def search(params, scope: all, paginate: true)
      config = search_config
      relation = scope
      relation = apply_text_search(relation, params[config[:search_key]], config[:on])
      relation = apply_range(relation, params, config[:range_on])
      config[:aggs_on].each { |column| relation = apply_facet_filter(relation, column, params[column]) }

      facets = build_facets(scope, params, config)
      relation = paginate_relation(relation, params, config) if paginate
      Result.new(records: relation, facets: facets)
    end

    private

    def paginate_relation(relation, params, config)
      requested = params[:per_page].presence&.to_i
      per_page = requested&.positive? ? [ requested, MAX_PER_PAGE ].min : config[:per_page]
      relation.page(params[:page].presence || 1).per(per_page)
    end

    def apply_text_search(relation, term, columns)
      valid = columns.select { |column| column_names.include?(column.to_s) }
      return relation if term.blank? || valid.empty?

      pattern = "%#{term.to_s.strip}%"
      clause = valid.map { |column| arel_table[column].matches(pattern) }.reduce(:or)
      relation.where(clause)
    end

    def apply_range(relation, params, column)
      return relation unless column && column_names.include?(column.to_s)

      min = params[:min].presence&.to_f
      max = params[:max].presence&.to_f
      relation = relation.where(arel_table[column].gteq(min)) if min&.positive?
      relation = relation.where(arel_table[column].lteq(max)) if max&.positive?
      relation
    end

    def apply_facet_filter(relation, column, value)
      return relation unless column_names.include?(column.to_s)

      values = Array(value).reject { |item| item.to_s.strip.empty? }
      return relation if values.empty?

      relation.where(column => normalize_facet_values(column, values))
    end

    def normalize_facet_values(column, values)
      if defined_enums.key?(column.to_s)
        values.map { |value| defined_enums[column.to_s][value.to_s] || value }
      elsif columns_hash[column.to_s]&.type == :boolean
        values.map { |value| ActiveModel::Type::Boolean.new.cast(value) }
      elsif column.to_s.end_with?("_id")
        values.map(&:to_i)
      else
        values.map(&:to_s)
      end
    end

    def build_facets(scope, params, config)
      return {} if config[:aggs_on].empty?

      base = scope.unscope(:includes, :order, :select)
      base = apply_text_search(base, params[config[:search_key]], config[:on])
      base = apply_range(base, params, config[:range_on])

      config[:aggs_on].each_with_object({}) do |column, facets|
        next unless column_names.include?(column.to_s)

        counting = base
        config[:aggs_on].reject { |other| other == column }.each do |other|
          counting = apply_facet_filter(counting, other, params[other])
        end
        facets[column.to_s] = format_facet(column, counting.group(column).count, config[:facet_limit], params[column])
      end
    end

    # Rank by count, cap to `limit`, but always keep any currently-selected value
    # (so an active filter on a long-tail option never disappears from the list).
    # Names are resolved only for the chosen rows, not the full high-cardinality set.
    def format_facet(column, counts, limit, selected)
      ranked = counts.sort_by { |_raw, count| -count }
      chosen = ranked.first(limit)
      if ranked.size > limit
        selected_values = Array(selected).map(&:to_s)
        chosen += ranked.drop(limit).select { |raw, _count| selected_values.include?(raw.to_s) }
      end

      names = association_name_map(column, chosen.map(&:first)) if column.to_s.end_with?("_id")
      chosen.map { |raw, count| { value: raw.to_s, label: facet_label(column, raw, names), count: count } }
    end

    def facet_label(column, raw, names)
      if defined_enums.key?(column.to_s)
        (defined_enums[column.to_s].key(raw) || raw).to_s.humanize
      elsif column.to_s.end_with?("_id")
        names[raw] || "—"
      elsif [ true, false ].include?(raw)
        raw ? "Yes" : "No"
      else
        raw.nil? ? "—" : raw.to_s.humanize
      end
    end

    def association_name_map(column, ids)
      reflection = reflect_on_association(column.to_s.sub(/_id\z/, "").to_sym)
      return {} unless reflection

      reflection.klass.where(id: ids.compact).index_by(&:id).transform_values do |record|
        record.try(:name) || record.try(:title) || record.id.to_s
      end
    end
  end
end
