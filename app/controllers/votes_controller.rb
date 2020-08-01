class VotesController < ApplicationController
  before_action :set_challenge, only: [:update]
  before_action :set_vote, only: [:show, :edit, :update, :destroy]

  # PATCH/PUT /votes/1
  # PATCH/PUT /votes/1.json
  def update
    respond_to do |format|
      if @vote.update(vote_params)
        format.html { redirect_to [@challenge], notice: 'Vote was successfully updated.' }
        format.json { render :show, status: :ok, location: @vote }
      else
        format.html { redirect_to [@challenge], notice: 'Error casting vote.'  }
        format.json { render json: @vote.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_challenge
      @challenge = Challenge.find_by_external_id!(params[:challenge_id])
    end

    def set_vote
      @vote = Vote.where(participant_id: session[:participant_id]).find(params[:id])
    end

    def vote_params
      params.require(:vote).permit(:vote)
    end
end
