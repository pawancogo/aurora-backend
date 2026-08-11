# frozen_string_literal: true

module Admin
  # Individual features/tasks nested under a Sprint.
  class SprintFeaturesController < BaseController
    before_action -> { require_permission!("roadmap.manage") }
    before_action :set_sprint
    before_action :set_feature, only: %i[edit update destroy]

    def new
      @feature = @sprint.sprint_features.new(position: (@sprint.sprint_features.maximum(:position) || 0) + 1)
    end

    def create
      @feature = @sprint.sprint_features.new(feature_params)
      if @feature.save
        redirect_to admin_sprints_path(anchor: "sprint-#{@sprint.id}"), notice: "Feature added."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @feature.update(feature_params)
        redirect_to admin_sprints_path(anchor: "sprint-#{@sprint.id}"), notice: "Feature updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @feature.destroy
      redirect_to admin_sprints_path(anchor: "sprint-#{@sprint.id}"), notice: "Feature deleted."
    end

    private

    def set_sprint
      @sprint = Sprint.find(params[:sprint_id])
    end

    def set_feature
      @feature = @sprint.sprint_features.find(params[:id])
    end

    def feature_params
      params.require(:sprint_feature).permit(:area, :title, :description, :technical_description, :position)
    end
  end
end
