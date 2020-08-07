require 'challenge_csv_formatter'

class ChallengesController < ApplicationController
  before_action :set_challenge, only: [:show]
  before_action :set_participant
  before_action :set_participation_state
  before_action :set_proposed_solution
  before_action :count_participants

  def show
    if @challenge.status == Challenge::Status::VOTING && @participant.present? && @participant.persisted?
      @current_vote = @participant.votes.find_by(round: @challenge.voting_round)
    end

    respond_to do |format|
      format.html
      format.csv { send_data ChallengeCsvFormatter.new(@challenge, host: request.host_with_port).to_csv, filename: "twentyfiveten-#{@challenge.external_id}-#{Date.today}.csv" }
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
      else
        @participant = Participant.new
      end
    rescue ActiveRecord::RecordNotFound
      @participant = Participant.new
    end

    def set_participation_state
      @participation_state = case @challenge.status
      when Challenge::Status::OPEN,
        Challenge::Status::FINISHED
        @participant.persisted? ? "active" : "unregistered"
      when Challenge::Status::VOTING
        @participant.persisted? && @current_vote ? "active" : "unregistered"
      end
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
