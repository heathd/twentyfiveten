class AdministratorsController < ApplicationController
  # Anyone can register as an administrator, and the login token is a secret,
  # so keep both from being hammered. Limits are per client IP.
  rate_limit to: 10, within: 1.hour, only: :create, name: "create"
  rate_limit to: 20, within: 10.minutes, only: :login, name: "login"

  # POST /administrators
  def create
    if current_administrator
      redirect_to admin_challenges_path
    else
      administrator = Administrator.create!
      session[:administrator_id] = administrator.administrator_id
      redirect_to admin_challenges_path, notice: "You're registered as an administrator."
    end
  end

  # POST /administrators/login
  def login
    params.require(:administrator_id)
    administrator = Administrator.find_by_administrator_id(params[:administrator_id])
    if administrator
      session[:administrator_id] = administrator.administrator_id
      redirect_to admin_challenges_path, notice: "Logged in successfully"
    else
      redirect_to root_path, notice: 'No administrator found with that code.'
    end
  end

  # POST /administrators/logout
  def logout
    session.delete(:administrator_id)
    redirect_to root_path, notice: 'Logged out'
  end

  private
    # The administrator in the session, if the session refers to a real one.
    def current_administrator
      return if session[:administrator_id].blank?

      Administrator.find_by_administrator_id(session[:administrator_id])
    end
end
