# frozen_string_literal: true
class Api::V1::MobileController < ApplicationController
  skip_before_action :authenticated
  before_action :require_current_user

  respond_to :json

  # The only models this API serves, keyed by the classified `class` param.
  # Each entry scopes records to the signed-in user and lists the only
  # attributes that may be serialised (no password, auth_token, SSN, DoB or
  # bank columns).
  MOBILE_MODELS = {
    "User" => {
      scope: ->(user) { User.where(id: user.id) },
      only: %w[id email first_name last_name created_at updated_at]
    },
    "Message" => {
      scope: ->(user) { user.messages },
      only: %w[id creator_id receiver_id message read created_at updated_at]
    },
    "PaidTimeOff" => {
      scope: ->(user) { PaidTimeOff.where(user_id: user.id) },
      only: %w[id user_id sick_days_taken sick_days_earned pto_taken pto_earned created_at updated_at]
    },
    "Performance" => {
      scope: ->(user) { Performance.where(user_id: user.id) },
      only: %w[id user_id date_submitted score comments reviewer created_at updated_at]
    },
    "Retirement" => {
      scope: ->(user) { Retirement.where(user_id: user.id) },
      only: %w[id user_id total employee_contrib employer_contrib created_at updated_at]
    },
    "Schedule" => {
      scope: ->(user) { Schedule.where(user_id: user.id) },
      only: %w[id user_id event_type date_begin date_end event_name event_desc created_at updated_at]
    },
    "WorkInfo" => {
      scope: ->(user) { WorkInfo.where(user_id: user.id) },
      only: %w[id user_id income bonuses years_worked created_at updated_at]
    }
  }.freeze

  def show
    if params[:class]
      resource = mobile_resource
      return head :not_found unless resource
      respond_with resource[:scope].call(current_user).find(params[:id]).to_json(only: resource[:only])
    end
  end

  def index
    if params[:class]
      resource = mobile_resource
      return head :not_found unless resource
      respond_with resource[:scope].call(current_user).to_json(only: resource[:only])
    else
      respond_with nil.to_json
    end
  end

  private

  def require_current_user
    head :unauthorized unless current_user
  end

  def mobile_resource
    MOBILE_MODELS[params[:class].to_s.classify]
  end
end
