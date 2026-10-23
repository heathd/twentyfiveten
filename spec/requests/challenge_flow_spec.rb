require 'rails_helper'

RSpec.describe "Challenge flow", type: :request do
  it "runs a challenge from creation through to finished results" do
    # Administrator creates a challenge
    post administrators_path
    expect(response).to redirect_to(admin_challenges_path)

    post admin_challenges_path, params: {
      challenge: {
        challenge_context: "Context for the challenge",
        challenge_prompt: "What big idea would you recommend?",
        first_step_prompt: "What first step would you take?"
      }
    }
    challenge = Challenge.last
    expect(challenge.status).to eq(Challenge::Status::OPEN)

    get admin_challenges_path
    expect(response).to have_http_status(:ok)

    # The same browser session joins as a participant and submits an idea
    get challenge_path(challenge)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("What big idea would you recommend?")

    post challenge_participants_path(challenge), params: { consent: "1" }
    participant = Participant.find_by!(challenge: challenge)

    post challenge_proposed_solutions_path(challenge), params: {
      proposed_solution: { narrative: "My <b>big</b> idea <script>alert(1)</script><img src=x onerror=alert(2)>", first_step: "Start small" }
    }
    expect(participant.reload.proposed_solution.narrative).to include("<script>")

    get challenge_path(challenge)
    expect(response).to have_http_status(:ok)

    # Other participants, enough that each can vote on 5 other ideas
    6.times do |i|
      p = Participant.create!(challenge_id: challenge.id, consent: true)
      p.create_proposed_solution!(challenge_id: challenge.id, narrative: "Idea #{i}", first_step: "Step #{i}")
    end

    # Voting opens and the participant casts a vote
    post open_voting_admin_challenge_path(challenge)
    challenge.reload
    expect(challenge.status).to eq(Challenge::Status::VOTING)
    expect(challenge.votes.count).to eq(7 * 5)

    get challenge_path(challenge)
    expect(response).to have_http_status(:ok)

    vote = participant.votes.find_by!(round: 1)
    patch challenge_vote_path(challenge, vote), params: { vote: { vote: 4 } }
    expect(vote.reload.vote).to eq(4)

    # Rounds advance to the end
    4.times do
      post next_round_admin_challenge_path(challenge)
      get challenge_path(challenge)
      expect(response).to have_http_status(:ok)
    end
    expect(challenge.reload.voting_round).to eq(5)

    post next_round_admin_challenge_path(challenge)
    expect(challenge.reload.status).to eq(Challenge::Status::FINISHED)

    # Results are shown, and exportable
    get challenge_path(challenge)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<b>big</b>")
    expect(response.body).not_to include("<script>alert(1)")
    expect(response.body).not_to include("onerror")

    get challenge_path(challenge, format: :csv)
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.body).to include("Total score")
  end
end
