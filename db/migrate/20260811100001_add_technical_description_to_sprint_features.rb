# frozen_string_literal: true

# Splits SprintFeature's single description into what shoppers/stakeholders
# care about (plain language) vs. what engineers care about (implementation
# detail) — the two audiences read very differently.
class AddTechnicalDescriptionToSprintFeatures < ActiveRecord::Migration[8.1]
  def change
    add_column :sprint_features, :technical_description, :text
  end
end
