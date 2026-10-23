require 'rails_helper'

# Limits are per client IP, or per participant for voting and proposals. They
# are deliberately generous: they stop floods, not normal use by a workshop.
RSpec.describe "Rate limiting", type: :request do
  let(:administrator) { Administrator.create! }
  let(:challenge)     { Challenge.create!(administrator: administrator, challenge_prompt: "A") }

  describe "registering administrators" do
    it "allows 10 an hour per IP, then responds 429" do
      10.times do
        reset!
        post administrators_path
        expect(response).to have_http_status(:found)
      end

      reset!
      expect { post administrators_path }.not_to change(Administrator, :count)
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "administrator login" do
    it "allows 20 attempts in 10 minutes per IP, then responds 429" do
      20.times do
        post login_administrators_path, params: { administrator_id: "guess" }
        expect(response).to have_http_status(:found)
      end

      post login_administrators_path, params: { administrator_id: administrator.administrator_id }
      expect(response).to have_http_status(:too_many_requests)
    end

    it "counts registering and logging in separately" do
      10.times { reset!; post administrators_path }
      reset!
      post administrators_path
      expect(response).to have_http_status(:too_many_requests)

      post login_administrators_path, params: { administrator_id: administrator.administrator_id }
      expect(response).to have_http_status(:found)
    end
  end

  describe "joining a challenge" do
    it "allows 300 joins in 10 minutes per IP, then responds 429" do
      300.times do
        reset!
        post challenge_participants_path(challenge), params: { consent: "1" }
        expect(response).to have_http_status(:found)
      end

      reset!
      expect { post challenge_participants_path(challenge), params: { consent: "1" } }
        .not_to change(Participant, :count)
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "proposals and votes for one participant" do
    before { post challenge_participants_path(challenge), params: { consent: "1" } }

    let(:participant) { Participant.find_by!(challenge_id: challenge.id) }

    it "limits proposal updates to 30 in 5 minutes" do
      post challenge_proposed_solutions_path(challenge),
           params: { proposed_solution: { narrative: "first", first_step: "s" } }
      solution = participant.reload.proposed_solution

      29.times do |i|
        patch challenge_proposed_solution_path(challenge, solution),
              params: { proposed_solution: { narrative: "edit #{i}", first_step: "s" } }
        expect(response).to have_http_status(:found)
      end

      patch challenge_proposed_solution_path(challenge, solution),
            params: { proposed_solution: { narrative: "too many", first_step: "s" } }
      expect(response).to have_http_status(:too_many_requests)
      expect(solution.reload.narrative).to eq("edit 28")
    end

    it "limits vote changes to 30 in 5 minutes" do
      ProposedSolution.create!(challenge_id: challenge.id, participant_id: participant.id, narrative: "mine", first_step: "m")
      6.times do |i|
        other = Participant.create!(challenge_id: challenge.id, consent: true)
        ProposedSolution.create!(challenge_id: challenge.id, participant_id: other.id, narrative: "idea #{i}", first_step: "s")
      end
      challenge.open_voting!
      vote = participant.votes.find_by!(round: 1)

      30.times do |i|
        patch challenge_vote_path(challenge, vote), params: { vote: { vote: (i % 5) + 1 } }
        expect(response).to have_http_status(:found)
      end

      patch challenge_vote_path(challenge, vote), params: { vote: { vote: 5 } }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "normal use of the whole flow" do
    it "is nowhere near the limits" do
      post administrators_path
      post admin_challenges_path, params: { challenge: { challenge_prompt: "Prompt" } }
      challenge = Challenge.last

      post challenge_participants_path(challenge), params: { consent: "1" }
      expect(response).to have_http_status(:found)
      post challenge_proposed_solutions_path(challenge),
           params: { proposed_solution: { narrative: "n", first_step: "f" } }
      expect(response).to have_http_status(:found)
    end
  end
end
