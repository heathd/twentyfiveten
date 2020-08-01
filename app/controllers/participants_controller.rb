class ParticipantsController < ApplicationController
  before_action :set_challenge, only: [:create]
  before_action :set_participant, only: [:show, :edit, :update, :destroy]

  # POST /participants
  # POST /participants.json
  def create
    if @challenge.status != 'open'
      redirect_to @challenge, notice: "Can't participate now, challenge already in progress"
    else
      @participant = Participant.new(challenge_id: @challenge.id)

      respond_to do |format|
        if @participant.save
          session[:participant_id] = @participant.id
          format.html { redirect_to @participant.challenge, notice: 'Participant was successfully created.' }
          format.json { render :show, status: :created, location: @participant }
        else
          format.html { redirect_to @participant.challenge, notice: 'Unable to create participant.' }
          format.json { render json: @participant.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_participant
      @participant = Participant.find(params[:id])
    end

    def set_challenge
      @challenge = Challenge.find_by_external_id(params[:challenge_id])
      unless @challenge
        redirect_to "/", notice: "Challenge not found"
      end
    end

    # Only allow a list of trusted parameters through.
    def participant_params
      params.permit()
    end
end
