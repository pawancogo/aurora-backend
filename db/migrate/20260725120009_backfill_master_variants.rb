# frozen_string_literal: true

# Products created before the master-variant pattern have no variant/inventory.
# Give each one a master variant (which auto-creates its inventory item), so the
# "every product owns a variant" invariant holds everywhere.
class BackfillMasterVariants < ActiveRecord::Migration[8.1]
  def up
    Product.reset_column_information
    Product.find_each do |product|
      next if product.variants.exists?(is_master: true)

      product.variants.create!(is_master: true)
    end
  end

  def down
    # Leave master variants in place; removing them would drop inventory + ledger.
  end
end
