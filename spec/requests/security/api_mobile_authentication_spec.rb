# frozen_string_literal: true
require "spec_helper"

# security-triage · railsgoat#06-c1 (CWE-306), commit f5951f1.
# The mobile API must not serve records to a caller without an authenticated principal:
# an anonymous request has to be halted with 401/403 and carry no data.
RSpec.describe "Api::V1::Mobile authentication (railsgoat#06-c1)", type: :request do
  let(:seeded_admin_email) { "admin@metacorp.com" }

  before { UserFixture.reset_all_users }

  shared_examples "denies the anonymous collection request" do |user_agent|
    it "answers 401/403 and returns no user records (User-Agent: #{user_agent})" do
      get "/api/v1/mobile", params: { class: "user" }, headers: { "HTTP_USER_AGENT" => user_agent }

      expect(response.status).to eq(401).or eq(403)
      expect(response.body).not_to include(seeded_admin_email)
      expect(response.body).not_to include("auth_token")
    end
  end

  include_examples "denies the anonymous collection request", "Mozilla/5.0 (Macintosh; Intel Mac OS X)"
  include_examples "denies the anonymous collection request", "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)"

  it "answers 401/403 and returns no data for a single record requested anonymously" do
    admin = User.find_by!(email: seeded_admin_email)

    get "/api/v1/mobile/#{admin.id}", params: { class: "user" }, headers: { "HTTP_USER_AGENT" => "Dalvik/2.1.0 (Linux; Android 14)" }

    expect(response.status).to eq(401).or eq(403)
    expect(response.body).not_to include(seeded_admin_email)
    expect(response.body).not_to include("auth_token")
  end
end
