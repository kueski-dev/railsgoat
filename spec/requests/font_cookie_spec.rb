# frozen_string_literal: true
require "spec_helper"

# Regression for railsgoat#26-c1 (CWE-79): the font preference taken from ?font= must be
# constrained to a plain CSS size before it is stored, and the layout must never emit the
# cookie content unescaped.
RSpec.describe "Font preference cookie", type: :request do
  let(:normal_user) { UserFixture.normal_user }
  let(:payload) { "</style><script>alert(1)</script>" }

  before do
    UserFixture.reset_all_users
    post "/sessions", params: { email: normal_user.email, password: normal_user.clear_password }
  end

  it "does not store a font value containing markup" do
    get "/dashboard/home", params: { font: payload }

    expect(response).to have_http_status(:ok)
    expect(cookies["font"].to_s).not_to include("<script>")
  end

  it "does not echo the markup from the query string into the page" do
    get "/dashboard/home", params: { font: payload }

    expect(response.body).not_to include(payload)
    expect(response.body).not_to include("<script>alert(1)</script>")
  end

  it "does not render a planted font cookie raw" do
    cookies["font"] = payload

    get "/dashboard/home"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(payload)
    expect(response.body).not_to include("<script>alert(1)</script>")
  end

  it "still applies a well-formed font size" do
    get "/dashboard/home", params: { font: "14px" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("font-size:14px")
  end
end
