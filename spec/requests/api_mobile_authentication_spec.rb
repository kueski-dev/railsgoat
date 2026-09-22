# frozen_string_literal: true
require "spec_helper"

# Regression for railsgoat#06-c1 (CWE-306): /api/v1/mobile must not return any record to
# a request without an authenticated principal, and its guard must halt the chain.
RSpec.describe "Mobile API authentication", type: :request do
  let(:ios_agent) { { "User-Agent" => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) ios" } }

  before { UserFixture.reset_all_users }

  it "rejects an anonymous collection request from a desktop client" do
    get "/api/v1/mobile", params: { class: "user" }

    expect(response).to have_http_status(:unauthorized).or have_http_status(:forbidden)
    expect(response.body).not_to include("admin@metacorp.com")
    expect(response.body).not_to include("auth_token")
  end

  it "rejects an anonymous collection request from a mobile client" do
    get "/api/v1/mobile", params: { class: "user" }, headers: ios_agent

    expect(response).to have_http_status(:unauthorized).or have_http_status(:forbidden)
    expect(response.body).not_to include("admin@metacorp.com")
  end

  it "rejects an anonymous single-record request" do
    admin = User.where(admin: true).first

    get "/api/v1/mobile/#{admin.id}", params: { class: "user" }, headers: ios_agent

    expect(response).to have_http_status(:unauthorized).or have_http_status(:forbidden)
    expect(response.body).not_to include(admin.email)
  end
end
