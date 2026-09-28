# frozen_string_literal: true
require "spec_helper"

# railsgoat#06-c1 (CWE-306): /api/v1/mobile must not serve data without an authenticated principal.
describe "Api::V1::Mobile authentication", type: :request do
  before { UserFixture.reset_all_users }

  it "refuses an anonymous request and returns no records" do
    get "/api/v1/mobile", params: { class: "user" }

    expect(response).not_to have_http_status(:ok)
    expect(response.body).not_to include("admin@metacorp.com")
  end

  it "refuses an anonymous request that claims a mobile User-Agent" do
    get "/api/v1/mobile", params: { class: "user" }, headers: { "User-Agent" => "Android" }

    expect(response).not_to have_http_status(:ok)
    expect(response.body).not_to include("admin@metacorp.com")
  end
end
