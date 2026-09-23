# frozen_string_literal: true
require "spec_helper"

describe Api::V1::MobileController do
  let(:user) { UserFixture.normal_user }
  let(:other_user) { UserFixture.admin_user }

  before { UserFixture.reset_all_users }

  def body
    JSON.parse(response.body)
  end

  context "without an authenticated user" do
    it "halts index with 401 and returns no records" do
      get :index, params: { class: "user" }, format: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to be_blank
    end

    it "halts show with 401 and returns no record" do
      get :show, params: { class: "user", id: other_user.id }, format: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to be_blank
    end

    it "does not treat a mobile User-Agent as a credential" do
      request.headers["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)"
      get :index, params: { class: "work_info" }, format: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to be_blank
    end
  end

  context "with an authenticated user" do
    it "returns only the current user's own record, without credentials" do
      get :index, params: { class: "user" }, session: { user_id: user.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(body.map { |r| r["id"] }).to eq([user.id])
      expect(body.first.keys).not_to include("password", "auth_token")
    end

    it "does not expose SSN or DoB columns" do
      get :index, params: { class: "work_info" }, session: { user_id: user.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(body.map { |r| r["user_id"] }).to eq([user.id])
      expect(body.first.keys).not_to include("SSN", "encrypted_ssn", "DoB")
    end

    it "does not expose bank account or routing numbers" do
      Pay.create!(user_id: user.id, bank_account_num: "123456789",
                  bank_routing_num: "987654321", percent_of_deposit: 100)
      get :index, params: { class: "pay" }, session: { user_id: user.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(body.map { |r| r["user_id"] }).to eq([user.id])
      expect(body.first.keys).not_to include("bank_account_num", "bank_routing_num")
    end

    it "does not return another user's record" do
      get :show, params: { class: "user", id: other_user.id }, session: { user_id: user.id }, format: :json

      expect(response).to have_http_status(:not_found)
      expect(response.body).to be_blank
    end

    it "rejects models outside the allowlist" do
      get :index, params: { class: "analytics" }, session: { user_id: user.id }, format: :json

      expect(response).to have_http_status(:not_found)
      expect(response.body).to be_blank
    end
  end
end
