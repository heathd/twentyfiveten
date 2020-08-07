class ChallengesController < ApplicationController
  before_action :set_challenge, only: [:show]
  before_action :set_participant
  before_action :set_proposed_solution
  before_action :count_participants

  def show
    if @challenge.status == Challenge::Status::VOTING && @participant.present?
      @current_vote = @participant.votes.find_by(round: @challenge.voting_round)
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

    def count_participants
      @num_participants = Participant.where(challenge_id: @challenge).count
      @num_proposals = Participant.joins(:proposed_solution).where(challenge_id: @challenge).count
    end
end
