class HomeController < ApplicationController
  def index
    @admin_id = session[:admin_id]
  end
end
