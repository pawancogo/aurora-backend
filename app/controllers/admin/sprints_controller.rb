# frozen_string_literal: true

module Admin
  # Roadmap: sprint-wise feature tracker, viewable/editable by every admin role.
  class SprintsController < BaseController
    before_action -> { require_permission!("roadmap.read") }, only: :index
    before_action -> { require_permission!("roadmap.manage") }, only: %i[new create edit update destroy]
    before_action :set_sprint, only: %i[edit update destroy]

    def index
      @sprints = Sprint.ordered
      @sprints = @sprints.where(status: Sprint.statuses[params[:status]]) if Sprint.statuses.key?(params[:status])
      @sprints = @sprints.where("title ILIKE :q OR goal ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
    end

    def new
      @sprint = Sprint.new(number: (Sprint.maximum(:number) || 0) + 1)
    end

    def create
      @sprint = Sprint.new(sprint_params)
      if @sprint.save
        redirect_to admin_sprints_path(anchor: "sprint-#{@sprint.id}"), notice: "Sprint created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @sprint.update(sprint_params)
        redirect_to admin_sprints_path(anchor: "sprint-#{@sprint.id}"), notice: "Sprint updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @sprint.destroy
      redirect_to admin_sprints_path, notice: "Sprint deleted."
    end

    private

    def set_sprint
      @sprint = Sprint.find(params[:id])
    end

    def sprint_params
      params.require(:sprint).permit(
        :number, :title, :goal, :status, :dependencies, :estimate, :started_on, :completed_on
      )
    end
  end
end
