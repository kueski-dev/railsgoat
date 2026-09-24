# frozen_string_literal: true
require "spec_helper"

# Security triage — railsgoat#26-c1 (CWE-79). Red test: demonstrates that
# params[:font] is stored in a cookie and rendered unescaped (`raw`) inside
# the shared layout's <style> block. See kueski-dev-railsgoat-findings-2026-09-22.md.
describe "railsgoat#26-c1 (CWE-79)", type: :request do
  before { UserFixture.reset_all_users }

  it "does not render the font param unescaped in the layout" do
    user = UserFixture.normal_user
    post "/sessions", params: {email: user.email, password: user.clear_password}

    payload = "</style><script>alert(1)</script>"
    get "/dashboard/home", params: {font: payload}

    expect(response.body).not_to include("<script>alert(1)</script>")
  end
end
