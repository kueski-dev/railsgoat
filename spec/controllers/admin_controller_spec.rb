# frozen_string_literal: true

require "spec_helper"

RSpec.describe AdminController, type: :controller do
  # Model specs seed users in before(:all) and leave them behind; start from an
  # empty users table so the administrator can be pinned to id 1.
  before { User.delete_all }

  let!(:admin) do
    User.create!(id: 1, email: "admin@metacorp.com", admin: true, first_name: "Admin", last_name: "",
                 password: "admin1234", password_confirmation: "admin1234")
  end
  let!(:normal_user) { UserFixture.normal_user }

  describe "as an authenticated non-admin user" do
    before { session[:user_id] = normal_user.id }

    it "refuses PATCH update_user with admin_id 1 and leaves the administrator unchanged" do
      expect {
        patch :update_user, params: { admin_id: "1", user: { email: "attacker@example.com",
                                                            password: "pwned123",
                                                            password_confirmation: "pwned123",
                                                            admin: "true" } }
      }.not_to change { admin.reload.attributes }

      expect(response).to redirect_to(root_url)
      expect(User.authenticate("admin@metacorp.com", "admin1234")).to eq(admin)
    end

    it "refuses POST delete_user with admin_id 1" do
      expect {
        post :delete_user, params: { admin_id: "1" }
      }.not_to change(User, :count)

      expect(response).to redirect_to(root_url)
    end

    %i[dashboard get_all_users analytics get_user].each do |action|
      it "refuses GET #{action} with admin_id 1" do
        get action, params: { admin_id: "1" }

        expect(response).to redirect_to(root_url)
      end
    end

    it "refuses GET get_user for any other user id" do
      get :get_user, params: { admin_id: normal_user.id }

      expect(response).to redirect_to(root_url)
    end
  end

  describe "as an administrator" do
    before { session[:user_id] = admin.id }

    %i[dashboard get_all_users analytics].each do |action|
      it "renders GET #{action} with admin_id 1, as linked from the sidebar" do
        get action, params: { admin_id: "1" }

        expect(response).to have_http_status(:ok)
      end
    end

    it "renders GET get_user for another user" do
      get :get_user, params: { admin_id: normal_user.id }

      expect(response).to have_http_status(:ok)
    end

    it "updates the edit-form fields of another user, including password and admin flag" do
      patch :update_user, params: { admin_id: normal_user.id, user: { email: "joe.new@schmoe.com",
                                                                     first_name: "Joseph",
                                                                     last_name: "S",
                                                                     password: "n3w passw0rd",
                                                                     password_confirmation: "n3w passw0rd",
                                                                     admin: "true" } }

      expect(response).to redirect_to(admin_get_all_users_path(admin.id))
      normal_user.reload
      expect(normal_user.first_name).to eq("Joseph")
      expect(normal_user.last_name).to eq("S")
      expect(normal_user.admin).to be true
      expect(User.authenticate("joe.new@schmoe.com", "n3w passw0rd")).to eq(normal_user)
    end

    it "keeps the current password when the password fields are left blank" do
      patch :update_user, params: { admin_id: normal_user.id, user: { first_name: "Joseph",
                                                                     password: "",
                                                                     password_confirmation: "" } }

      expect(normal_user.reload.first_name).to eq("Joseph")
      expect(User.authenticate(normal_user.email, normal_user.clear_password)).to eq(normal_user)
    end

    it "ignores attributes that are not part of the edit form" do
      original_token = normal_user.auth_token

      patch :update_user, params: { admin_id: normal_user.id, user: { first_name: "Joseph",
                                                                     auth_token: "attacker-chosen" } }

      expect(normal_user.reload.first_name).to eq("Joseph")
      expect(normal_user.auth_token).to eq(original_token)
    end
  end
end
