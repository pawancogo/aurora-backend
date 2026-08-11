# frozen_string_literal: true

module SprintsHelper
  STATUS_CLASSES = { "planned" => "chip sys", "in_progress" => "stock-badge low", "completed" => "chip ok" }.freeze

  def sprint_status_chip(sprint)
    content_tag(:span, sprint.status.humanize, class: STATUS_CLASSES.fetch(sprint.status, "chip sys"))
  end
end
