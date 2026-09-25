# frozen_string_literal: true
require "spec_helper"

# railsgoat#26-c1 (CWE-79): the font preference must never reach the layout's <style> block unescaped.
describe "Dashboard font preference", type: :request do
  before do
    UserFixture.reset_all_users
    post "/sessions", params: { email: "jmmastey@metacorp.com", password: "railsgoat!" }
  end

  it "does not let a font value break out of the <style> block" do
    get "/dashboard/home", params: { font: "</style><script>window.__xss=1</script>" }
    get "/dashboard/home"

    expect(response.body).not_to include("<script>window.__xss=1</script>")
    expect(response.body).not_to include("</style><script>")
  end

  it "still applies a legitimate font size" do
    get "/dashboard/home", params: { font: "20px" }
    get "/dashboard/home"

    expect(response.body).to include("font-size:20px")
  end
end
