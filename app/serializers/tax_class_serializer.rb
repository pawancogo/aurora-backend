# frozen_string_literal: true

class TaxClassSerializer
  def initialize(tax_class)
    @tax_class = tax_class
  end

  def as_json(*)
    {
      id: @tax_class.id,
      name: @tax_class.name,
      rate: @tax_class.rate.to_f,
      hsn_code: @tax_class.hsn_code
    }
  end
end
