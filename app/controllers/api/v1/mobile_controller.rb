# frozen_string_literal: true
class Api::V1::MobileController < ApplicationController
  skip_before_action :authenticated
  before_action :require_authenticated_user

  respond_to :json

  # Explicit allowlist of the only models (and, for each, the only
  # attributes) the mobile API may return. Every record is additionally
  # scoped to the authenticated user below, and none of these models or
  # attribute lists include credentials, auth tokens, SSNs or bank data.
  MOBILE_MODELS = {
    "retirement" => {klass: Retirement, attributes: %w[id total employee_contrib employer_contrib]},
    "paid_time_off" => {klass: PaidTimeOff, attributes: %w[id sick_days_taken sick_days_earned pto_taken pto_earned]},
    "performance" => {klass: Performance, attributes: %w[id date_submitted score comments]}
  }.freeze

  def show
    config = mobile_model_config
    return head :not_found unless config

    record = config[:klass].where(user_id: current_user.id).find_by(id: params[:id])
    return head :not_found unless record

    respond_with record.as_json(only: config[:attributes])
  end

  def index
    if params[:class]
      config = mobile_model_config
      return head :not_found unless config

      records = config[:klass].where(user_id: current_user.id)
      respond_with records.as_json(only: config[:attributes])
    else
      respond_with nil.to_json
    end
  end

  private

  # Anonymous requests must never reach the actions above. Unlike the
  # previous guard, this halts the filter chain (via head) instead of
  # returning an ignored boolean.
  def require_authenticated_user
    head :unauthorized unless current_user
  end

  def mobile_model_config
    MOBILE_MODELS[params[:class].to_s]
  end
end
