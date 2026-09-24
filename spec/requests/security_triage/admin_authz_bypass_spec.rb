# frozen_string_literal: true
require "spec_helper"

# Security triage — railsgoat#27-c1 (CWE-863). Red test: demonstrates that a
# non-admin user can bypass the `administrative` filter by requesting
# admin_id=1, and rewrite the seeded admin's password.
# See kueski-dev-railsgoat-findings-2026-09-22.md.
describe "railsgoat#27-c1 (CWE-863)", type: :request do
  before { UserFixture.reset_all_users }

  it "does not let a non-admin user update the admin account via admin_id=1" do
    normal_user = UserFixture.normal_user
    admin = UserFixture.admin_user
    original_password_digest = admin.password

    post "/sessions", params: {email: normal_user.email, password: normal_user.clear_password}

    patch "/admin/1/update_user",
          params: {user: {password: "hax0red123!", password_confirmation: "hax0red123!"}}

    admin.reload
    expect(admin.password).to eq(original_password_digest)
  end
end
