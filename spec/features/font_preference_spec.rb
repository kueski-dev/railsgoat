# frozen_string_literal: true
require "spec_helper"

# Regression coverage for the font size preference: DashboardController#home
# stores params[:font] in cookies[:font], and app/views/layouts/application.html.erb
# emits that cookie inside a <style> block on every page. Only a numeric size
# with a CSS unit may reach the page; anything else must be dropped.
#
# Unlike the specs in spec/vulnerabilities, this is not a training exercise:
# it must pass in both training and maintainer mode.
feature "font size preference" do
  let(:normal_user) { UserFixture.normal_user }
  let(:payload) { "</style><script>alert('font-xss')</script>" }

  before(:each) do
    UserFixture.reset_all_users
  end

  def login_and_wait(user)
    login(user)
    expect(page).to have_current_path(home_dashboard_index_path)
  end

  scenario "the header's font size links are applied and remembered on later pages" do
    login_and_wait(normal_user)

    visit "/dashboard/home?font=200%25"
    expect(page.html).to include("body { font-size:200% !important;}")

    visit "/dashboard/home"
    expect(page.html).to include("body { font-size:200% !important;}")

    visit "/dashboard/home?font=8pt"
    expect(page.html).to include("body { font-size:8pt !important;}")
  end

  scenario "a script payload in ?font= is neither rendered nor remembered" do
    login_and_wait(normal_user)

    visit "/dashboard/home?font=#{CGI.escape(payload)}"
    expect(page.html).not_to include(payload)
    expect(page.html).not_to include("alert('font-xss')")

    visit "/dashboard/home"
    expect(page.html).not_to include("alert('font-xss')")
  end

  scenario "a rejected ?font= value keeps the previously chosen size" do
    login_and_wait(normal_user)

    visit "/dashboard/home?font=8pt"
    visit "/dashboard/home?font=#{CGI.escape(payload)}"

    expect(page.html).to include("body { font-size:8pt !important;}")
    expect(page.html).not_to include("alert('font-xss')")
  end

  scenario "a malicious font cookie that is already stored is not rendered" do
    login_and_wait(normal_user)

    page.driver.browser.set_cookie("font=#{CGI.escape(payload)}; path=/", URI.parse(page.current_url))
    visit "/dashboard/home"

    expect(page.html).not_to include("alert('font-xss')")
    expect(page.html).not_to include("font-size:</style>")
  end
end
