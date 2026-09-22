# frozen_string_literal: true
class ApplicationController < ActionController::Base
  before_action :authenticated, :has_info, :create_analytic, :mailer_options
  helper_method :current_user, :is_admin?, :sanitize_font

  # Our security guy keep talking about sea-surfing, cool story bro.
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception

  private

  def mailer_options
    ActionMailer::Base.default_url_options[:protocol] = request.protocol
    ActionMailer::Base.default_url_options[:host]     = request.host_with_port
  end

  def current_user
    @current_user ||= (
      User.find_by(auth_token: cookies[:auth_token].to_s) ||
      User.find_by(id: session[:user_id].to_s)
    )
  end

  def authenticated
     path = request.fullpath.present? ? root_url(url: request.fullpath) : root_url
     redirect_to path and reset_session if !current_user
  end

  def is_admin?
    current_user.admin if current_user
  end

  def administrative
    if !is_admin?
     redirect_to root_url
   end
  end

  def has_info
    redirect = false
    if current_user
      begin
      if !(current_user.retirement || current_user.paid_time_off || current_user.paid_time_off.schedule || current_user.work_info || current_user.performance)
        redirect = true
      end
      rescue
         redirect = true
      end
    end
    redirect_to home_dashboard_index_path if redirect
  end

  def create_analytic
    Analytics.create({ ip_address: request.remote_ip, referrer: request.referrer, user_agent: request.user_agent})
  end

  FONT_SIZE_PATTERN = /\A\d{1,3}(\.\d{1,2})?(px|pt|em|rem|%)\z/

  # Returns the value only when it is a plain CSS size (number + unit); nil otherwise.
  # Used both when storing the font cookie and when rendering it, so a planted cookie
  # value never reaches the page.
  def sanitize_font(css)
    value = css.to_s.strip
    value.match?(FONT_SIZE_PATTERN) ? value : nil
  end
end
