class ProposedSolutionsController < ApplicationController
  before_action :set_challenge
  before_action :set_participant
  before_action :require_open_challenge
  before_action :set_proposed_solution, only: [:update]

  # POST /challenges/:challenge_id/proposed_solutions
  def create
    if @participant.proposed_solution.present?
      redirect_to @challenge, notice: 'You have already submitted a proposal.'
    else
      @proposed_solution = ProposedSolution.new(
        proposed_solution_params.merge(participant_id: @participant.id, challenge_id: @challenge.id)
      )

      if @proposed_solution.save
        redirect_to @challenge, notice: 'Proposed solution was successfully created.'
      else
        redirect_to @challenge, notice: 'Unable to save your proposal.'
      end
    end
  end

  # PATCH/PUT /challenges/:challenge_id/proposed_solutions/:id
  def update
    if @proposed_solution.update(proposed_solution_params)
      redirect_to @challenge, notice: 'Proposed solution was successfully updated.'
    else
      redirect_to @challenge, notice: 'Unable to save your proposal.'
    end
  end

  private
    def set_challenge
      @challenge = Challenge.find_by_external_id!(params[:challenge_id])
    end

    # Only a participant of this challenge may touch proposals. A missing or
    # foreign participant id in the session raises RecordNotFound (404).
    def set_participant
      @participant = Participant.where(challenge_id: @challenge.id).find(session[:participant_id])
    end

    def require_open_challenge
      unless @challenge.status == Challenge::Status::OPEN
        redirect_to @challenge, notice: "Can't change proposals now, challenge already in progress"
      end
    end

    # Scoped to the current participant, so other people's proposals look like they don't exist.
    def set_proposed_solution
      @proposed_solution = ProposedSolution.where(
        participant_id: @participant.id,
        challenge_id: @challenge.id
      ).find(params[:id])
    end

    # Ownership is never taken from params.
    def proposed_solution_params
      params.require(:proposed_solution).permit(:narrative, :first_step)
    end
end
