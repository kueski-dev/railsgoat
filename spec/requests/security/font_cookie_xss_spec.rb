# frozen_string_literal: true
require "spec_helper"

# security-triage · railsgoat#26-c1 (CWE-79), commit f5951f1.
# The font preference must be constrained before it is stored, and the layout must never emit
# the cookie content unescaped: a script-capable value must not reach the page as markup.
RSpec.describe "Font preference cookie in the application layout (railsgoat#26-c1)", type: :request do
  let(:user) { UserFixture.normal_user }
  let(:marker) { "window.__railsgoat_xss_26=1" }
  let(:payload) { "</style><script>#{marker}</script>" }

  before do
    UserFixture.reset_all_users
    post "/sessions", params: { email: user.email, password: user.clear_password }
  end

  it "does not echo a script-capable font value from the URL into the page" do
    get "/dashboard/home", params: { font: payload }

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("<script>#{marker}</script>")
  end

  it "does not replay a script-capable font value planted in the URL into later pages" do
    get "/dashboard/home", params: { font: payload }
    get "/dashboard/home"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("<script>#{marker}</script>")
  end

  it "does not render a script-capable font cookie unescaped even when the cookie is already set" do
    cookies["font"] = payload

    get "/dashboard/home"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("<script>#{marker}</script>")
  end
end
