# frozen_string_literal: true

FactoryBot.define do
  factory :product_question do
    product
    customer
    body { "Does this run true to size?" }
    status { :pending }

    trait :published do
      status { :published }
    end
  end

  factory :product_answer do
    association :question, factory: :product_question
    customer
    body { "Yes, I ordered my usual size and it fit well." }
    status { :pending }

    trait :from_store do
      customer { nil }
      admin_user
      status { :published }
      body { "Yes — this style runs true to size." }
    end

    trait :published do
      status { :published }
    end
  end
end
