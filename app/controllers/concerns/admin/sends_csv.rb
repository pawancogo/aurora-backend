# frozen_string_literal: true

require "csv"

module Admin
  # Shared CSV download helper for list screens.
  module SendsCsv
    extend ActiveSupport::Concern

    EXPORT_LIMIT = 5_000

    def send_csv(basename, headers)
      body = CSV.generate do |csv|
        csv << headers
        yield csv
      end
      send_data body,
                filename: "#{basename}-#{Date.current.iso8601}.csv",
                type: "text/csv; charset=utf-8"
    end
  end
end
