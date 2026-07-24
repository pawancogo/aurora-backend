# frozen_string_literal: true

module Api
  module V1
    module Admin
      class NavigationItemsController < Api::V1::BaseController
        include AdminAuthentication

        before_action -> { authorize_permission!("navigation.read") }, only: %i[index show]
        before_action -> { authorize_permission!("navigation.manage") }, only: %i[create update destroy reorder]

        # GET /api/v1/admin/navigation_items?location=header — full tree (incl. hidden).
        def index
          location = params[:location].presence || "header"
          render_success(Navigation::TreeBuilder.new(location: location, scope: :admin).as_json)
        end

        def show
          item = NavigationItem.find(params[:id])
          render_success(NavigationItemSerializer.new(item).as_json)
        end

        def create
          item = NavigationItem.create!(navigation_params)
          render_success(NavigationItemSerializer.new(item).as_json, status: :created)
        end

        def update
          item = NavigationItem.find(params[:id])
          item.update!(navigation_params)
          render_success(NavigationItemSerializer.new(item).as_json)
        end

        def destroy
          NavigationItem.find(params[:id]).destroy!
          render_success({ message: "Navigation item deleted." })
        end

        # POST /api/v1/admin/navigation_items/reorder
        # Body: { items: [{ id, parent_id, position }, ...] }
        def reorder
          updates = reorder_params
          NavigationItem.transaction do
            updates.each do |u|
              NavigationItem.where(id: u[:id]).update_all(parent_id: u[:parent_id], position: u[:position])
            end
          end
          Navigation::TreeCache.clear!
          render_success({ message: "Reordered #{updates.size} item(s)." })
        end

        private

        def navigation_params
          params.require(:navigation_item).permit(
            :parent_id, :location, :label, :slug, :url, :link_type, :icon, :image_url,
            :position, :visible, :open_in_new_tab, :starts_at, :ends_at, :meta_title, :meta_description
          )
        end

        def reorder_params
          params.permit(items: %i[id parent_id position]).require(:items).map do |item|
            { id: item[:id], parent_id: item[:parent_id].presence, position: item[:position] }
          end
        end
      end
    end
  end
end
