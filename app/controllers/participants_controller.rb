class ParticipantsController < ApplicationController
  # Generous, because a whole workshop may join from one shared office IP.
  rate_limit to: 300, within: 10.minutes, only: :create

  before_action :set_challenge, only: [:create]

  # POST /participants
  # POST /participants.json
  def create
    if @challenge.status != 'open'
      redirect_to @challenge, notice: "This challenge has already started, so new participants can't join."
    else
      @participant = Participant.new(participant_params.merge(challenge_id: @challenge.id))

      if @participant.save
        session[:participant_id] = @participant.id
        redirect_to @participant.challenge, notice: "You've joined this challenge."
      else
        redirect_to @participant.challenge, notice: "Unable to join. #{@participant.errors[:consent].join(", ")}."
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
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
