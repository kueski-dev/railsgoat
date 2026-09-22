# frozen_string_literal: true
class Api::V1::MobileController < ApplicationController
  skip_before_action :authenticated
  # The app-wide login gate is skipped because it redirects; an API client gets 401 instead.
  before_action :authenticate_api_user!
  before_action :mobile_request?

  respond_to :json

  def show
    if params[:class]
      model = params[:class].classify.constantize
      respond_with model.find(params[:id]).to_json
    end
  end

  def index
    if params[:class]
      model = params[:class].classify.constantize
      respond_with model.all.to_json
    else
      respond_with nil.to_json
    end
  end

  private

  def authenticate_api_user!
    head :unauthorized unless current_user
  end

  # A before_action only halts the chain when the response is performed, so the guard
  # must render/head instead of returning a boolean.
  def mobile_request?
    mobile = if session[:mobile_param]
               session[:mobile_param] == "1"
             else
               request.user_agent =~ /ios|android/i
             end
    head :forbidden unless mobile
  end
end
