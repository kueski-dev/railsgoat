# frozen_string_literal: true
require "spec_helper"

# railsgoat#27-c1 (CWE-863): AdminController must authorize every action, whatever :admin_id says.
describe "Admin authorization", type: :request do
  before { UserFixture.reset_all_users }

  def login_as(email, password)
    post "/sessions", params: { email: email, password: password }
  end

  context "as a non-admin user" do
    before { login_as("jmmastey@metacorp.com", "railsgoat!") }

    it "is denied the admin user list at admin_id=1" do
      get "/admin/1/get_all_users"

      expect(response).to have_http_status(:redirect)
      expect(response.body).not_to include("admin@metacorp.com")
    end

    it "is denied another user's edit form through get_user" do
      other = User.find_by(email: "admin@metacorp.com")

      get "/admin/#{other.id}/get_user"

      expect(response).to have_http_status(:redirect)
      expect(response.body).not_to include(other.email)
    end

    it "cannot rewrite the administrator's account at admin_id=1" do
      admin = User.find_by(id: 1)
      expect(admin&.admin).to be(true) # precondition: the bypassed id is the seeded administrator

      patch "/admin/1/update_user", params: { user: { email: "attacker@example.com" } }

      expect(response).to have_http_status(:redirect)
      expect(admin.reload.email).to eq("admin@metacorp.com")
    end
  end

  context "as the administrator" do
    before { login_as("admin@metacorp.com", "admin1234") }

    it "still reaches the admin dashboard" do
      get "/admin/1/dashboard"

      expect(response).to have_http_status(:ok)
    end
  end
end
