class AdministratorsController < ApplicationController
  before_action :clear_stale_session, only: [:create]
  before_action :set_administrator, only: [:show, :edit, :update, :destroy]

  # GET /administrators
  # GET /administrators.json
  def index
    @administrators = Administrator.all
  end

  # GET /administrators/1
  # GET /administrators/1.json
  def show
  end

  def login
    params.require(:administrator_id)
    @administrator = Administrator.find_by_administrator_id(params[:administrator_id])
    if @administrator
      session[:administrator_id] = @administrator.administrator_id
      redirect_to admin_challenges_path, notice: "Logged in successfully"
    else
      redirect_to home_index_path, notice: 'Administrator not found'
    end
  end

  # GET /administrators/new
  def new
    @administrator = Administrator.new
  end

  # GET /administrators/1/edit
  def edit
  end

  # POST /administrators
  # POST /administrators.json
  def create
    if session[:administrator_id].present?
      redirect_to admin_challenges_path
    else
      @administrator = Administrator.new(administrator_params)
    end

    respond_to do |format|
      if @administrator.save
        session[:administrator_id] = @administrator.administrator_id
        format.html { redirect_to admin_challenges_path, notice: 'Administrator was successfully created.' }
        format.json { render :show, status: :created, location: @administrator }
      else
        format.html { render :new }
        format.json { render json: @administrator.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /administrators/1
  # PATCH/PUT /administrators/1.json
  def update
    respond_to do |format|
      if @administrator.update(administrator_params)
        format.html { redirect_to @administrator, notice: 'Administrator was successfully updated.' }
        format.json { render :show, status: :ok, location: @administrator }
      else
        format.html { render :edit }
        format.json { render json: @administrator.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /administrators/1
  # DELETE /administrators/1.json
  def destroy
    @administrator.destroy
    respond_to do |format|
      format.html { redirect_to administrators_url, notice: 'Administrator was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def clear_stale_session
      if session[:administrator_id].present?
        @administrator = Administrator.find_by_administrator_id!(session[:administrator_id])
      end
    rescue ActiveRecord::RecordNotFound
      session.delete(:administrator_id)
    end

    def set_administrator
      @administrator = Administrator.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def administrator_params
      params.permit()
    end
end
