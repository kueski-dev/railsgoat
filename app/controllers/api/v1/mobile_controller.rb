# frozen_string_literal: true
class Api::V1::MobileController < ApplicationController
  # This is a JSON API: instead of the HTML login redirect performed by
  # `authenticated`, an unauthenticated request is halted with 401.
  skip_before_action :authenticated
  before_action :require_authenticated_user
  before_action :load_resource

  respond_to :json

  # The only resources this API may return. Every scope is restricted to the
  # signed-in user's own rows and every record is projected to the listed
  # columns, so credentials (password, auth_token), SSN/DoB and bank account
  # numbers are never serialised.
  RESOURCES = {
    "user" => {
      scope: ->(user) { User.where(id: user.id) },
      attrs: %w[id email first_name last_name admin created_at updated_at]
    },
    "retirement" => {
      scope: ->(user) { Retirement.where(user_id: user.id) },
      attrs: %w[id user_id total employee_contrib employer_contrib created_at updated_at]
    },
    "paid_time_off" => {
      scope: ->(user) { PaidTimeOff.where(user_id: user.id) },
      attrs: %w[id user_id sick_days_taken sick_days_earned pto_taken pto_earned created_at updated_at]
    },
    "schedule" => {
      scope: ->(user) { Schedule.where(user_id: user.id) },
      attrs: %w[id user_id event_type event_name event_desc date_begin date_end created_at updated_at]
    },
    "work_info" => {
      scope: ->(user) { WorkInfo.where(user_id: user.id) },
      attrs: %w[id user_id income bonuses years_worked created_at updated_at]
    },
    "performance" => {
      scope: ->(user) { Performance.where(user_id: user.id) },
      attrs: %w[id user_id date_submitted score comments reviewer created_at updated_at]
    },
    "pay" => {
      scope: ->(user) { Pay.where(user_id: user.id) },
      attrs: %w[id user_id percent_of_deposit created_at updated_at]
    },
    "message" => {
      scope: ->(user) { Message.where(receiver_id: user.id) },
      attrs: %w[id creator_id receiver_id message read created_at updated_at]
    }
  }.freeze

  def show
    record = @scope.find_by(id: params[:id])
    return head :not_found unless record

    respond_with record.attributes.slice(*@attrs)
  end

  def index
    respond_with @scope.map { |record| record.attributes.slice(*@attrs) }
  end

  private

  def require_authenticated_user
    head :unauthorized unless current_user
  end

  def load_resource
    resource = RESOURCES[params[:class].to_s.underscore.singularize]
    return head :not_found unless resource

    @scope = resource[:scope].call(current_user)
    @attrs = resource[:attrs]
  end
end
