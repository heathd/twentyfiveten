class ParticipantsController < ApplicationController
  before_action :set_challenge, only: [:create]
  before_action :set_participant, only: [:show, :edit, :update, :destroy]

  # POST /participants
  # POST /participants.json
  def create
    if @challenge.status != 'open'
      redirect_to @challenge, notice: "Can't participate now, challenge already in progress"
    else
      @participant = Participant.new(participant_params.merge(challenge_id: @challenge.id))

      if @participant.save
        session[:participant_id] = @participant.id
        redirect_to @participant.challenge, notice: 'Participant was successfully created.'
      else
        redirect_to @participant.challenge, notice: "Unable to register -- #{@participant.errors[:consent].join(", ")}"
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
      params.permit(:consent)
    end
end
