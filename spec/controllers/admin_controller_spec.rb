# frozen_string_literal: true
require "spec_helper"

RSpec.describe AdminController, type: :controller do
  let(:password) { "thi$ 1s cOmplExEr" }
  let!(:admin) do
    User.create!(first_name: "Admin", last_name: "User", email: "admin@example.com",
                 password: password, password_confirmation: password, admin: true)
  end
  let!(:normal_user) do
    User.create!(first_name: "Joe", last_name: "Schmoe", email: "joe@schmoe.com",
                 password: password, password_confirmation: password, admin: false)
  end

  def login_as(user)
    session[:user_id] = user.id
  end

  context "as a non-admin user" do
    before { login_as(normal_user) }

    it "denies dashboard even when admin_id is \"1\"" do
      get :dashboard, params: { admin_id: "1" }

      expect(response).to redirect_to(root_url)
    end

    it "denies get_user" do
      get :get_user, params: { admin_id: admin.id }

      expect(response).to redirect_to(root_url)
    end

    it "does not let update_user with admin_id \"1\" change any account" do
      expect {
        patch :update_user, params: { admin_id: "1",
                                      user: { password: "hijacked1", password_confirmation: "hijacked1", admin: "true" } }
      }.not_to(change { User.order(:id).pluck(:password, :admin) })

      expect(response).to redirect_to(root_url)
    end

    it "does not let delete_user with admin_id \"1\" remove an account" do
      expect {
        post :delete_user, params: { admin_id: "1" }
      }.not_to(change { User.count })

      expect(response).to redirect_to(root_url)
    end
  end

  context "as an administrator" do
    before { login_as(admin) }

    it "still reaches the dashboard with admin_id \"1\"" do
      get :dashboard, params: { admin_id: "1" }

      expect(response).to have_http_status(:success)
    end

    it "updates only allowlisted attributes through update_user" do
      original_token = normal_user.auth_token

      patch :update_user, params: { admin_id: normal_user.id,
                                    user: { first_name: "Renamed", auth_token: "forged" } }

      normal_user.reload
      expect(normal_user.first_name).to eq("Renamed")
      expect(normal_user.auth_token).to eq(original_token)
      expect(response).to redirect_to(admin_get_all_users_path(admin.id))
    end
  end
end
