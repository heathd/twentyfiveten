class ChallengesController < ApplicationController
  before_action :set_challenge, only: [:show]
  before_action :set_participant
  before_action :set_proposed_solution
  before_action :count_participants

  # GET /challenges
  # GET /challenges.json
  def index
    @challenges = Challenge.all
  end

  # GET /challenges/1
  # GET /challenges/1.json
  def show
    if @challenge.status == Challenge::Status::VOTING && @participant.present?
      @current_vote = @participant.votes.find_by(round: @challenge.voting_round)
    end
  end

  # GET /challenges/new
  def new
    @challenge = Challenge.new
  end

  # GET /challenges/1/edit
  def edit
  end

  # POST /challenges
  # POST /challenges.json
  def create
    @challenge = Challenge.new(challenge_params)

    respond_to do |format|
      if @challenge.save
        format.html { redirect_to @challenge, notice: 'Challenge was successfully created.' }
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
      format.html { redirect_to challenges_url, notice: 'Challenge was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_challenge
      @challenge = Challenge.find_by_external_id(params[:id])
    end

    def set_participant
      if session[:participant_id]
        @participant = Participant.where(challenge_id: @challenge).find(session[:participant_id])
      end
    rescue ActiveRecord::RecordNotFound
      session.delete(:participant_id)
    end

    def set_proposed_solution
      if @participant.nil?
        return
      end

      unless @participant.proposed_solution.present?
        @participant.build_proposed_solution(challenge_id: @challenge.id)
      end
    end

    # Only allow a list of trusted parameters through.
    def challenge_params
      params.require(:challenge).permit(:challenge_text)
    end

    def count_participants
      @num_participants = Participant.where(challenge_id: @challenge).count
      @num_proposals = Participant.joins(:proposed_solution).where(challenge_id: @challenge).count
    end
end
