class Admin::ChallengesController < ApplicationController
  before_action :require_administrator
  before_action :set_challenge, only: [:show, :edit, :update, :destroy, :open_voting, :next_round, :reset]

  # GET /challenges
  # GET /challenges.json
  def index
    @challenges = Challenge.where(administrator: @administrator).order(created_at: :desc).all
  end

  # GET /challenges/1
  # GET /challenges/1.json
  def show
  end

  # GET /challenges/new
  def new
    @challenge = Challenge.new(challenge_text: "If you were ten times bolder, what big idea would you recommend?\n\nWhat first step would you take to get started?")
  end

  # GET /challenges/1/edit
  def edit
  end

  # POST /challenges
  # POST /challenges.json
  def create
    @challenge = Challenge.new(challenge_params.merge(administrator_id: @administrator.id))

    respond_to do |format|
      if @challenge.save
        format.html { redirect_to [:admin, :challenges], notice: 'Challenge was successfully created.' }
        format.json { render :show, status: :created, location: @challenge }
      else
        format.html { render :new }
        format.json { render json: @challenge.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /challenges/1
  # PATCH/PUT /challenges/1.json
  def update
    respond_to do |format|
      if @challenge.update(challenge_params)
        format.html { redirect_to @challenge, notice: 'Challenge was successfully updated.' }
        format.json { render :show, status: :ok, location: @challenge }
      else
        format.html { render :edit }
        format.json { render json: @challenge.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /challenges/1
  # DELETE /challenges/1.json
  def destroy
    @challenge.destroy
    respond_to do |format|
      format.html { redirect_to admin_challenges_url, notice: 'Challenge was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def open_voting
    @challenge.open_voting!
    redirect_to [:admin, :challenges], notice: 'Voting open'
  end

  def next_round
    @challenge.next_round!
    redirect_to [:admin, :challenges], notice: "Round #{@challenge.voting_round} open"
  end

  def reset
    @challenge.reset!
    redirect_to [:admin, :challenges], notice: "All votes cancelled, call for participation re-opened"
  end

  def require_administrator
    @administrator_id = session[:administrator_id]
    @administrator = Administrator.find_by_administrator_id!(@administrator_id)
    unless @administrator_id.present?
      redirect_to "/", notice: 'Administrator session is required'
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_challenge
      @challenge = Challenge.find_by_external_id(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def challenge_params
      params.require(:challenge).permit(:challenge_text)
    end
end
