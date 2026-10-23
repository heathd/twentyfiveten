require 'rails_helper'

# A participant must only be able to change or delete their own proposed solution.
# ProposedSolutionsController looks records up by params[:id] alone, so these
# are expected to fail until the lookup is scoped to the session's participant.
RSpec.describe "Proposed solution authorization", type: :request do
  let(:administrator) { Administrator.create! }
  let(:challenge)       { Challenge.create!(administrator: administrator, challenge_prompt: "A") }
  let(:other_challenge) { Challenge.create!(administrator: administrator, challenge_prompt: "B") }

  let(:victim) { Participant.create!(challenge_id: challenge.id, consent: true) }
  let!(:victims_solution) do
    ProposedSolution.create!(
      challenge_id: challenge.id,
      participant_id: victim.id,
      narrative: "The victim's idea",
      first_step: "The victim's first step"
    )
  end

  # Registers the current session as a new participant in the given challenge.
  def join(challenge)
    post challenge_participants_path(challenge), params: { consent: "1" }
    Participant.where(challenge_id: challenge.id).order(:id).last
  end

  def submit_own_solution(challenge)
    post challenge_proposed_solutions_path(challenge), params: {
      proposed_solution: { narrative: "My own idea", first_step: "My first step" }
    }
    ProposedSolution.where(challenge_id: challenge.id).order(:id).last
  end

  # The controller may raise or redirect once it has already acted; what matters
  # for these tests is the state of the database afterwards, so ignore the response.
  def attempt
    yield
  rescue StandardError
    nil
  end

  shared_examples "cannot modify someone else's solution" do
    it "does not let the narrative be changed" do
      attempt do
        patch challenge_proposed_solution_path(target_challenge, victims_solution),
              params: { proposed_solution: { narrative: "Overwritten", first_step: "Overwritten" } }
      end

      victims_solution.reload
      expect(victims_solution.narrative).to eq("The victim's idea")
      expect(victims_solution.first_step).to eq("The victim's first step")
    end

    it "does not let ownership be taken over or moved to another challenge" do
      attempt do
        patch challenge_proposed_solution_path(target_challenge, victims_solution),
              params: { proposed_solution: { narrative: "Overwritten", first_step: "Overwritten" } }
      end

      victims_solution.reload
      expect(victims_solution.participant_id).to eq(victim.id)
      expect(victims_solution.challenge_id).to eq(challenge.id)
    end

    it "responds as if the solution does not exist" do
      patch challenge_proposed_solution_path(target_challenge, victims_solution),
            params: { proposed_solution: { narrative: "Overwritten", first_step: "Overwritten" } }

      expect(response).to have_http_status(:not_found)
    end

    it "does not let the solution be deleted" do
      attempt { delete challenge_proposed_solution_path(target_challenge, victims_solution) }

      expect(ProposedSolution.exists?(victims_solution.id)).to be(true)
    end
  end

  context "when the other participant is in the same challenge" do
    let(:target_challenge) { challenge }

    before do
      join(challenge)
      submit_own_solution(challenge)
    end

    include_examples "cannot modify someone else's solution"
  end

  context "when the other participant is in a different challenge" do
    let(:target_challenge) { challenge }

    before { join(other_challenge) }

    include_examples "cannot modify someone else's solution"
  end

  context "when not a participant at all" do
    let(:target_challenge) { challenge }

    include_examples "cannot modify someone else's solution"
  end

  describe "creating a proposal" do
    it "does not allow a second proposal for the same participant" do
      join(challenge)
      submit_own_solution(challenge)

      expect { submit_own_solution(challenge) }.not_to change(ProposedSolution, :count)
    end

    it "does not allow a proposal from someone who has not joined" do
      expect { submit_own_solution(challenge) }.not_to change(ProposedSolution, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "does not allow a proposal in a challenge the participant has not joined" do
      join(other_challenge)

      expect { submit_own_solution(challenge) }.not_to change(ProposedSolution, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "once voting has started" do
    it "does not allow a participant to change their proposal" do
      join(challenge)
      own = submit_own_solution(challenge)
      challenge.update!(status: Challenge::Status::VOTING, voting_round: 1)

      patch challenge_proposed_solution_path(challenge, own),
            params: { proposed_solution: { narrative: "Changed mid-vote", first_step: "x" } }

      expect(own.reload.narrative).to eq("My own idea")
    end
  end

  describe "unused scaffold routes" do
    before { join(challenge) }

    it "does not list, show, or edit proposals" do
      get challenge_proposed_solutions_path(challenge)
      expect(response).to have_http_status(:not_found)

      get "/challenges/#{challenge.external_id}/proposed_solutions/#{victims_solution.id}"
      expect(response).to have_http_status(:not_found)

      get "/challenges/#{challenge.external_id}/proposed_solutions/#{victims_solution.id}/edit"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "an unknown challenge" do
    it "is a 404 on the challenge page" do
      get "/challenges/doesnotexist"
      expect(response).to have_http_status(:not_found)
    end

    it "is a 404 when submitting a proposal" do
      post "/challenges/doesnotexist/proposed_solutions",
           params: { proposed_solution: { narrative: "x", first_step: "y" } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "a participant's own solution" do
    it "can still be updated by its owner" do
      join(challenge)
      own = submit_own_solution(challenge)

      patch challenge_proposed_solution_path(challenge, own),
            params: { proposed_solution: { narrative: "Edited", first_step: "Edited step" } }

      expect(own.reload.narrative).to eq("Edited")
      expect(own.first_step).to eq("Edited step")
    end
  end
end
