# frozen_string_literal: true
class UsersController < ApplicationController
  skip_before_action :has_info
  skip_before_action :authenticated, only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    user = User.new(user_params)
    if user.save
      session[:user_id] = user.id
      redirect_to home_dashboard_index_path
    else
      @user = user
      flash[:error] = user.errors.full_messages.to_sentence
      redirect_to :signup
    end
  end

  def account_settings
    @user = current_user
  end

  def update
    message = false

    # The identifier is only ever passed as a bound value, never interpolated
    # into a SQL fragment; anything that is not a plain integer matches no row.
    requested_id = params[:user][:id].to_s
    user = User.find_by(id: requested_id) if requested_id.match?(/\A\d+\z/)

    if user
      user.update(user_params_without_password)
      if params[:user][:password].present? && (params[:user][:password] == params[:user][:password_confirmation])
        user.password = params[:user][:password]
      end
      message = true if user.save!
      respond_to do |format|
        format.html { redirect_to user_account_settings_path(user_id: current_user.id) }
        format.json { render json: {msg: message ? "success" : "false "} }
      end
    else
      flash[:error] = "Could not update user!"
      redirect_to user_account_settings_path(user_id: current_user.id)
    end
  end

  private

  # Signup may only assign the self-service attributes the form sends;
  # privilege-bearing columns (admin, id, auth_token) are never mass-assignable.
  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation)
  end

  # unpermitted attributes are ignored in production
  def user_params_without_password
    params.require(:user).permit(:email, :admin, :first_name, :last_name)
  end
end
