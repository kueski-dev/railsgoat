# frozen_string_literal: true
class DashboardController < ApplicationController
  skip_before_action :has_info
  layout false, only: [:change_graph]

  def home
    @user = current_user

    # See if the user has a font preference; only a plain CSS size is persisted.
    if params[:font]
      safe_font = sanitize_font(params[:font])
      cookies[:font] = safe_font if safe_font
    end
  end

  def change_graph
    self.try(params[:graph])

    if params[:graph] == "bar_graph"
      render "dashboard/bar_graph"
    else
      @user = current_user
      render "dashboard/pie_charts"
    end
  end
end
