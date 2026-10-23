class VotesController < ApplicationController
  rate_limit to: 30, within: 5.minutes, by: -> { session[:participant_id] || request.remote_ip }

  before_action :set_challenge
  before_action :set_vote
  before_action :require_open_round

  # PATCH/PUT /challenges/:challenge_id/votes/:id
  def update
    if @vote.update(vote_params)
      redirect_to @challenge, notice: 'Vote recorded.'
    else
      redirect_to @challenge, notice: "Sorry, your vote couldn't be saved. Please try again."
    end
  end

  private
    def set_challenge
      @challenge = Challenge.find_by_external_id!(params[:challenge_id])
    end

    # Scoped to the current participant and this challenge, so other people's
    # votes (or votes from another challenge) look like they don't exist.
    def set_vote
      @vote = Vote.where(participant_id: session[:participant_id], challenge_id: @challenge.id).find(params[:id])
    end

    # Only the round that is currently open can be scored or amended.
    def require_open_round
      unless @challenge.status == Challenge::Status::VOTING && @vote.round == @challenge.voting_round
        redirect_to @challenge, notice: "That vote can't be changed now."
      end
    end

    def vote_params
      params.require(:vote).permit(:vote)
    end
end
