# frozen_string_literal: true

FactoryBot.define do
  factory :tax_class do
    sequence(:name) { |n| "Tax #{n}" }
    rate { 18 }
    hsn_code { "0000" }
  end
end
