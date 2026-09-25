# frozen_string_literal: true

require "spec_helper"

RSpec.describe Api::V1::MobileController, type: :controller do
  let(:normal_user) { UserFixture.normal_user }
  let(:admin_user) { UserFixture.admin_user }

  before do
    UserFixture.reset_all_users
  end

  def json_response
    JSON.parse(response.body)
  end

  context "without an authenticated user" do
    it "refuses GET #index and returns no records" do
      get :index, params: { class: "user" }, format: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).not_to include(admin_user.email)
      expect(response.body).not_to include(admin_user.auth_token)
    end

    it "does not accept a mobile User-Agent as a credential" do
      request.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) iOS"

      get :index, params: { class: "work_info" }, format: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).not_to include(admin_user.work_info.SSN)
    end

    it "refuses GET #show and returns no record" do
      get :show, params: { class: "user", id: admin_user.id }, format: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).not_to include(admin_user.email)
    end
  end

  context "with an authenticated user" do
    before do
      session[:user_id] = normal_user.id
    end

    it "returns only the signed-in user's own record, without credential columns" do
      get :index, params: { class: "user" }, format: :json

      expect(response).to have_http_status(:success)
      expect(json_response.map { |u| u["id"] }).to eq([normal_user.id])
      expect(json_response.first).to include("email" => normal_user.email, "first_name" => "Joe")
      expect(json_response.first.keys).not_to include("password", "auth_token")
    end

    it "shows the signed-in user's own record" do
      get :show, params: { class: "user", id: normal_user.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(json_response).to include("id" => normal_user.id, "email" => normal_user.email)
      expect(json_response.keys).not_to include("password", "auth_token")
    end

    it "does not show another user's record" do
      expect {
        get :show, params: { class: "user", id: admin_user.id }, format: :json
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns the user's own work info without SSN or date of birth" do
      get :index, params: { class: "work_info" }, format: :json

      expect(response).to have_http_status(:success)
      expect(json_response.map { |w| w["user_id"] }).to eq([normal_user.id])
      expect(json_response.first).to include("income" => normal_user.work_info.income)
      expect(json_response.first.keys).not_to include("SSN", "DoB", "encrypted_ssn")
    end

    it "returns the user's own paid time off" do
      get :index, params: { class: "paid_time_off" }, format: :json

      expect(response).to have_http_status(:success)
      expect(json_response.map { |p| p["user_id"] }).to eq([normal_user.id])
    end

    it "refuses models outside the allowlist" do
      %w[pay key_management analytics].each do |klass|
        get :index, params: { class: klass }, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    it "still returns null when no class is requested" do
      get :index, format: :json

      expect(response).to have_http_status(:success)
      expect(response.body).to eq("null")
    end
  end
end
