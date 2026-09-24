# frozen_string_literal: true
require "spec_helper"

# Security triage — railsgoat#06-c1 (CWE-306). Red test: demonstrates that an
# anonymous request to /api/v1/mobile dumps ActiveRecord data with no
# authenticated principal. See kueski-dev-railsgoat-findings-2026-09-22.md.
describe "railsgoat#06-c1 (CWE-306)", type: :request do
  before { UserFixture.reset_all_users }

  it "does not return user records to an unauthenticated caller" do
    get "/api/v1/mobile", params: {class: "user"}

    expect(response).not_to have_http_status(:ok)
    expect(response.body).not_to include("admin@metacorp.com")
    expect(response.body).not_to include("auth_token")
  end

  it "does not return work_info (SSN/DoB) to an unauthenticated caller" do
    get "/api/v1/mobile", params: {class: "work_info"}

    expect(response).not_to have_http_status(:ok)
    expect(response.body).not_to include("555-55-5555")
  end
end
