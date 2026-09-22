# frozen_string_literal: true
require "spec_helper"

# Regression for railsgoat#27-c1 (CWE-863): the `administrative` filter must run for
# every AdminController action, regardless of the :admin_id route segment.
RSpec.describe "Admin authorization", type: :request do
  let(:normal_user) { UserFixture.normal_user }

  before do
    UserFixture.reset_all_users
    post "/sessions", params: { email: normal_user.email, password: normal_user.clear_password }
    expect(normal_user.reload.admin).to be_falsey
  end

  it "does not render the admin dashboard for a non-admin using admin_id=1" do
    get "/admin/1/dashboard"

    expect(response).not_to have_http_status(:ok)
    expect(response).to redirect_to(root_url)
  end

  it "does not let a non-admin change the seeded admin's password via admin_id=1" do
    admin = User.where(admin: true).first
    expect(admin.id).to eq(1) # the bypass is specific to admin_id == "1"; guard against a false green
    original_digest = admin.password

    patch "/admin/1/update_user", params: { user: { password: "pwned123", password_confirmation: "pwned123" } }

    expect(User.find(admin.id).password).to eq(original_digest)
  end

  it "does not serve another user's edit form (get_user) to a non-admin" do
    admin = User.where(admin: true).first

    get "/admin/#{admin.id}/get_user"

    expect(response).not_to have_http_status(:ok)
    expect(response).to redirect_to(root_url)
  end
end
