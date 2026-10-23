require 'rails_helper'

# A participant may only score the idea assigned to them in the round that is
# currently open, with a score of 1 to 5, while the challenge is in voting.
RSpec.describe "Voting", type: :request do
  let(:administrator)   { Administrator.create! }
  let!(:challenge)      { Challenge.create!(administrator: administrator, challenge_prompt: "A") }
  let(:other_challenge) { Challenge.create!(administrator: administrator, challenge_prompt: "B") }

  # The current session joins the challenge as a real participant.
  let!(:me) do
    post challenge_participants_path(challenge), params: { consent: "1" }
    Participant.find_by!(challenge_id: challenge.id)
  end

  before do
    ProposedSolution.create!(challenge_id: challenge.id, participant_id: me.id, narrative: "mine", first_step: "m")
    6.times do |i|
      other = Participant.create!(challenge_id: challenge.id, consent: true)
      ProposedSolution.create!(challenge_id: challenge.id, participant_id: other.id, narrative: "idea #{i}", first_step: "s")
    end
    challenge.open_voting!
  end

  def my_vote(round)
    me.votes.find_by!(round: round)
  end

  def cast(vote, value, in_challenge: challenge)
    patch challenge_vote_path(in_challenge, vote), params: { vote: { vote: value } }
  end

  describe "casting a score in the current round" do
    it "records the score" do
      cast(my_vote(1), 4)

      expect(my_vote(1).vote).to eq(4)
    end

    it "can be amended while the round is open" do
      cast(my_vote(1), 4)
      cast(my_vote(1), 2)

      expect(my_vote(1).vote).to eq(2)
    end
  end

  describe "the score value" do
    [0, 6, -3, 1000, 1_000_000].each do |bad_score|
      it "rejects #{bad_score}" do
        vote = my_vote(1)
        cast(vote, 3)
        cast(vote, bad_score)

        expect(vote.reload.vote).to eq(3)
      end
    end

    it "does not let a score be cleared once cast" do
      vote = my_vote(1)
      cast(vote, 3)
      cast(vote, "")

      expect(vote.reload.vote).to eq(3)
    end

    it "accepts every score from 1 to 5" do
      (1..5).each do |score|
        cast(my_vote(1), score)
        expect(my_vote(1).vote).to eq(score)
      end
    end
  end

  describe "the round" do
    it "does not allow a vote for an earlier round to be changed" do
      cast(my_vote(1), 3)
      challenge.next_round!

      cast(my_vote(1), 5)

      expect(my_vote(1).vote).to eq(3)
    end

    it "does not allow a vote for a later round to be cast early" do
      cast(my_vote(3), 5)

      expect(my_vote(3).vote).to be_nil
    end
  end

  describe "the challenge status" do
    it "does not allow votes to be changed once the challenge is finished" do
      cast(my_vote(1), 3)
      5.times { challenge.next_round! }
      expect(challenge.reload.status).to eq(Challenge::Status::FINISHED)

      cast(my_vote(1), 5)

      expect(my_vote(1).vote).to eq(3)
    end

    it "does not allow votes to be changed after voting has been reset" do
      vote = my_vote(1)
      cast(vote, 3)
      challenge.reset!

      cast(vote, 5)

      expect(Vote.find_by(id: vote.id)).to be_nil
    end
  end

  describe "ownership" do
    it "does not allow another participant's vote to be changed" do
      theirs = Vote.where.not(participant_id: me.id).find_by!(round: 1)

      cast(theirs, 5)

      expect(response).to have_http_status(:not_found)
      expect(theirs.reload.vote).to be_nil
    end

    it "does not allow a vote to be changed through a different challenge's URL" do
      vote = my_vote(1)

      cast(vote, 5, in_challenge: other_challenge)

      expect(response).to have_http_status(:not_found)
      expect(vote.reload.vote).to be_nil
    end

    it "does not allow a visitor who has not joined to vote" do
      vote = Vote.where(round: 1).first
      reset!   # drop the participant session

      cast(vote, 5)

      expect(response).to have_http_status(:not_found)
      expect(vote.reload.vote).to be_nil
    end
  end

  describe "an unknown challenge" do
    it "is a 404" do
      patch "/challenges/doesnotexist/votes/#{my_vote(1).id}", params: { vote: { vote: 3 } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "unused scaffold routes" do
    it "does not expose votes for listing or showing" do
      get "/challenges/#{challenge.external_id}/votes"
      expect(response).to have_http_status(:not_found)

      get "/challenges/#{challenge.external_id}/votes/#{my_vote(1).id}"
      expect(response).to have_http_status(:not_found)
    end
  end
end
