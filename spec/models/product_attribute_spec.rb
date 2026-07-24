# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductAttribute do
  it "normalizes the code to a lowercase slug" do
    attribute = create(:product_attribute, name: "Screen Size", code: "Screen Size")
    expect(attribute.code).to eq("screen_size")
  end

  it "derives the code from the name when blank" do
    attribute = ProductAttribute.new(name: "RAM Size", code: "")
    attribute.valid?
    expect(attribute.code).to eq("ram_size")
  end

  it "requires a unique code" do
    create(:product_attribute, code: "color")
    expect(build(:product_attribute, code: "color")).not_to be_valid
  end

  it "orders and destroys its values" do
    attribute = create(:product_attribute)
    attribute.attribute_values.create!(value: "B", position: 2)
    attribute.attribute_values.create!(value: "A", position: 1)

    expect(attribute.attribute_values.map(&:value)).to eq(%w[A B])
    expect { attribute.destroy }.to change(AttributeValue, :count).by(-2)
  end
end

RSpec.describe AttributeValue do
  it "normalizes the code from the value" do
    attribute = create(:product_attribute, :color)
    value = attribute.attribute_values.create!(value: "Deep Blue")
    expect(value.code).to eq("deep_blue")
  end

  it "requires the code to be unique within its attribute" do
    attribute = create(:product_attribute)
    attribute.attribute_values.create!(value: "Red", code: "red")
    dup = attribute.attribute_values.build(value: "Red again", code: "red")
    expect(dup).not_to be_valid
  end
end
