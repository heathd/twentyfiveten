require 'rails_helper'

# The administrator drives a challenge through open -> voting (rounds 1..5) -> finished,
# and can reset a voting challenge back to open. Each transition must only be possible
# from the right state; otherwise a double click or a stale page corrupts the challenge.
RSpec.describe "Challenge lifecycle", type: :request do
  let(:administrator) { Administrator.create! }
  let!(:challenge)    { Challenge.create!(administrator: administrator, challenge_prompt: "A") }
  let(:participants_count) { 7 }

  before do
    participants_count.times do |i|
      participant = Participant.create!(challenge_id: challenge.id, consent: true)
      ProposedSolution.create!(challenge_id: challenge.id, participant_id: participant.id, narrative: "idea #{i}", first_step: "s")
    end

    post login_administrators_path, params: { administrator_id: administrator.administrator_id }
  end

  def votes_per_challenge
    participants_count * 5
  end

  def open_voting;  post open_voting_admin_challenge_path(challenge); end
  def next_round;   post next_round_admin_challenge_path(challenge);  end
  def reset;        post reset_admin_challenge_path(challenge);       end

  def start_voting!
    challenge.open_voting!
    challenge.reload
  end

  def finish!
    start_voting!
    5.times { challenge.next_round! }
    challenge.reload
  end

  describe "opening voting" do
    it "opens voting and schedules every vote once" do
      open_voting

      expect(response).to redirect_to(admin_challenges_path)
      expect(challenge.reload.status).to eq(Challenge::Status::VOTING)
      expect(challenge.voting_round).to eq(1)
      expect(challenge.votes.count).to eq(votes_per_challenge)
    end

    it "does not schedule the votes a second time (for example on a double click)" do
      open_voting
      open_voting

      expect(response).to redirect_to(admin_challenges_path)
      expect(challenge.votes.count).to eq(votes_per_challenge)
    end

    it "does not rewind a voting challenge that is already part way through" do
      start_voting!
      2.times { challenge.next_round! }
      expect(challenge.reload.voting_round).to eq(3)

      open_voting

      expect(challenge.reload.voting_round).to eq(3)
      expect(challenge.votes.count).to eq(votes_per_challenge)
    end

    it "does not reopen voting on a finished challenge" do
      finish!
      votes_before = challenge.votes.count

      open_voting

      expect(challenge.reload.status).to eq(Challenge::Status::FINISHED)
      expect(challenge.votes.count).to eq(votes_before)
    end
  end

  describe "advancing rounds" do
    before { start_voting! }

    it "moves to the next round" do
      next_round

      expect(response).to redirect_to(admin_challenges_path)
      expect(challenge.reload.voting_round).to eq(2)
    end

    it "finishes the challenge after round 5" do
      5.times { next_round }

      expect(challenge.reload.status).to eq(Challenge::Status::FINISHED)
      expect(challenge.voting_round).to be_nil
    end
  end

  describe "what the administrator is told" do
    it "reports the round that has opened" do
      start_voting!
      next_round
      expect(flash[:notice]).to eq("Round 2 open")
    end

    it "reports when voting has finished" do
      start_voting!
      5.times { next_round }
      expect(flash[:notice]).to eq("Voting finished")
    end

    it "explains why a refused action did nothing" do
      next_round
      expect(flash[:notice]).to eq("Rounds can only be advanced while voting is open")

      start_voting!
      open_voting
      expect(flash[:notice]).to eq("Voting can only be opened on a challenge that is open")
    end
  end

  describe "advancing a challenge that is not voting" do
    it "is rejected before voting has started" do
      next_round

      expect(response).to redirect_to(admin_challenges_path)
      expect(challenge.reload.status).to eq(Challenge::Status::OPEN)
      expect(challenge.voting_round).to be_nil
    end

    it "is rejected once the challenge is finished" do
      finish!

      next_round

      expect(response).to redirect_to(admin_challenges_path)
      expect(challenge.reload.status).to eq(Challenge::Status::FINISHED)
      expect(challenge.voting_round).to be_nil
    end
  end

  describe "resetting" do
    before { start_voting! }

    it "cancels the votes and reopens the call for participation" do
      reset

      expect(response).to redirect_to(admin_challenges_path)
      expect(challenge.reload.status).to eq(Challenge::Status::OPEN)
      expect(challenge.votes.count).to eq(0)
    end

    it "clears the voting round so a reset challenge looks like a new one" do
      2.times { challenge.next_round! }

      reset

      expect(challenge.reload.voting_round).to be_nil
    end

    it "can then be opened for voting again from round 1" do
      2.times { challenge.next_round! }
      reset

      open_voting

      expect(challenge.reload.status).to eq(Challenge::Status::VOTING)
      expect(challenge.voting_round).to eq(1)
      expect(challenge.votes.count).to eq(votes_per_challenge)
    end

    it "cannot then be advanced as if voting were still running" do
      2.times { challenge.next_round! }
      reset

      next_round

      expect(challenge.reload.status).to eq(Challenge::Status::OPEN)
      expect(challenge.voting_round).to be_nil
    end
  end
end
