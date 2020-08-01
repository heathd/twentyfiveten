class HomeController < ApplicationController
  before_action :set_administrator

  def index
    @administrator = session[:administrator_id]
  end

  def set_administrator
    if session[:administrator_id]
      @administrator = Administrator.find_by_administrator_id!(session[:administrator_id])
    end
  rescue ActiveRecord::RecordNotFound
    session.delete(:administrator_id)
    redirect_to "/", notice: "Administrator not found"
  end
end
