# frozen_string_literal: true
require "spec_helper"

# security-triage · railsgoat#27-c1 (CWE-863), commit f5951f1.
# The administrative filter must run unconditionally for every AdminController action: a
# non-admin requesting any /admin/:admin_id/* URL, including admin_id=1 and get_user, is
# denied and no record is read or written.
RSpec.describe "Admin authorization for every admin_id (railsgoat#27-c1)", type: :request do
  let(:user) { UserFixture.normal_user }
  let(:admin) do
    seeded = UserFixture.admin_user
    # The seeded administrator is user 1 in a fresh database; keep that invariant even when
    # earlier examples advanced the SQLite sequence, so admin_id=1 addresses the admin record.
    seeded.update_columns(id: 1) unless seeded.id == 1
    User.find(1)
  end

  before do
    UserFixture.reset_all_users
    post "/sessions", params: { email: user.email, password: user.clear_password }
  end

  it "does not serve the admin dashboard to a non-admin using admin_id=1" do
    get "/admin/1/dashboard"

    expect(response).not_to have_http_status(:ok)
  end

  it "does not list every user to a non-admin using admin_id=1" do
    get "/admin/1/get_all_users"

    expect(response).not_to have_http_status(:ok)
    expect(response.body).not_to include(admin.email)
  end

  it "does not let a non-admin rewrite the administrator record using admin_id=1" do
    original_email = admin.email
    original_first_name = admin.first_name

    patch "/admin/1/update_user", params: { user: { email: "attacker@example.com", first_name: "Owned" } }

    expect(admin.reload.email).to eq(original_email)
    expect(admin.first_name).to eq(original_first_name)
  end

  it "does not expose another user's edit form to a non-admin (get_user is not exempt)" do
    get "/admin/#{admin.id}/get_user"

    expect(response).not_to have_http_status(:ok)
    expect(response.body).not_to include(admin.email)
  end
end
