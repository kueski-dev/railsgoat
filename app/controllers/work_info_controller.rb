# frozen_string_literal: true
class WorkInfoController < ApplicationController
  def index
    # Only the authenticated user's own record is rendered; the :user_id route
    # segment is not trusted to select another user's work info.
    @user = current_user
    if !(@user) || @user.admin
      flash[:error] = "Sorry, no user with that user id exists"
      redirect_to home_dashboard_index_path
    end
  end

end
