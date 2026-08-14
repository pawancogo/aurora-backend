# frozen_string_literal: true

FactoryBot.define do
  factory :address do
    customer
    full_name { "Jane Doe" }
    phone { "9999999999" }
    line1 { "123 Main St" }
    city { "Mumbai" }
    state { "Maharashtra" }
    postal_code { "400001" }
    country { "IN" }
  end
end
