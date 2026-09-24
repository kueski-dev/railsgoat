# frozen_string_literal: true
class DashboardController < ApplicationController
  skip_before_action :has_info
  layout false, only: [:change_graph]

  # Only accept simple CSS length values (e.g. "8pt", "200%", "1.5em") as a
  # font-size preference; anything else is rejected so it can never carry
  # markup or script content into the cookie.
  FONT_SIZE_FORMAT = /\A\d{1,3}(\.\d{1,2})?(px|pt|em|rem|%)\z/

  def home
    @user = current_user

    # See if the user has a font preference
    if params[:font] && params[:font].to_s.match?(FONT_SIZE_FORMAT)
      cookies[:font] = params[:font]
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
