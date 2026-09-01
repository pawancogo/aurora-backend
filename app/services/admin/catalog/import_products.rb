# frozen_string_literal: true

require "csv"

module Admin
  module Catalog
    # Upserts products from a CSV (sku, name, status, price, mrp, brand, category).
    # Existing rows match on SKU; missing SKU generates one. Price is in rupees.
    class ImportProducts
      Result = Data.define(:created, :updated, :errors)

      HEADERS = %w[sku name status price mrp brand category].freeze

      def initialize(io:, actor: nil)
        @io = io
        @actor = actor
      end

      def call
        created = 0
        updated = 0
        errors = []

        CSV.parse(csv_body, headers: true, encoding: "UTF-8",
                            header_converters: [ ->(h) { utf8(h).strip.downcase } ]).each.with_index(2) do |row, line|
          sku = utf8(row["sku"]).strip
          name = utf8(row["name"]).strip
          if name.blank?
            errors << "Line #{line}: name is required"
            next
          end

          product = sku.present? ? Product.kept.find_by(sku: sku) : nil
          was_new = product.nil?
          product ||= Product.new(sku: sku.presence, currency: "INR")
          product.name = name
          product.status = normalize_status(row["status"])
          product.brand = find_or_create_named(Brand, row["brand"])
          product.category = find_or_create_named(Category, row["category"])

          unless product.save
            errors << "Line #{line}: #{product.errors.full_messages.to_sentence}"
            next
          end

          apply_price(product, row)
          was_new ? created += 1 : updated += 1
        end

        Result.new(created: created, updated: updated, errors: errors)
      rescue CSV::MalformedCSVError => e
        Result.new(created: 0, updated: 0, errors: [ "Could not parse CSV: #{e.message}" ])
      end

      private

      def csv_body
        data = @io.read.to_s.force_encoding(Encoding::UTF_8)
        data = data.delete_prefix("\uFEFF") if data.valid_encoding?
        data
      end

      def normalize_status(value)
        key = utf8(value).strip.downcase
        Product.statuses.key?(key) ? key : "draft"
      end

      def find_or_create_named(klass, name)
        name = utf8(name).strip
        return nil if name.blank?

        klass.kept.find_or_create_by!(name: name)
      end

      def apply_price(product, row)
        attrs = {}
        attrs[:price_cents] = rupees_to_cents(row["price"]) if utf8(row["price"]).present?
        attrs[:mrp_cents] = rupees_to_cents(row["mrp"]) if utf8(row["mrp"]).present?
        return if attrs.empty?

        product.master_variant.update!(attrs)
      end

      def rupees_to_cents(value)
        (utf8(value).to_f * 100).round
      end

      def utf8(value)
        value.to_s.dup.force_encoding(Encoding::UTF_8)
      end
    end
  end
end
