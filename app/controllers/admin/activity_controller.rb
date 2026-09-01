# frozen_string_literal: true

module Admin
  # Recent PaperTrail versions attributed to signed-in staff (Sprint 21 feed;
  # full reports stay Sprint 22).
  class ActivityController < BaseController
    def index
      @items, @versions = Activity.paginate(params)
    end
  end
end
