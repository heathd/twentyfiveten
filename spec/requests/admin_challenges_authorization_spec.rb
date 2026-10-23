require 'rails_helper'

# external_id is public (it is in the participant URL), so administrators must only
# be able to manage challenges that belong to them.
RSpec.describe "Admin challenge authorization", type: :request do
  let(:owner)    { Administrator.create! }
  let(:intruder) { Administrator.create! }
  let!(:challenge) { Challenge.create!(administrator: owner, challenge_prompt: "Owned by owner") }

  def log_in_as(administrator)
    post login_administrators_path, params: { administrator_id: administrator.administrator_id }
  end

  context "when logged in as a different administrator" do
    before { log_in_as(intruder) }

    it "cannot edit the challenge" do
      get edit_admin_challenge_path(challenge)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot update the challenge" do
      patch admin_challenge_path(challenge), params: { challenge: { challenge_prompt: "Hijacked" } }

      expect(response).to have_http_status(:not_found)
      expect(challenge.reload.challenge_prompt).to eq("Owned by owner")
    end

    it "cannot delete the challenge" do
      delete admin_challenge_path(challenge)

      expect(response).to have_http_status(:not_found)
      expect(Challenge.exists?(challenge.id)).to be(true)
    end

    it "cannot open voting" do
      post open_voting_admin_challenge_path(challenge)

      expect(response).to have_http_status(:not_found)
      expect(challenge.reload.status).to eq(Challenge::Status::OPEN)
    end

    it "cannot advance rounds or reset" do
      challenge.update!(status: Challenge::Status::VOTING, voting_round: 1)

      post next_round_admin_challenge_path(challenge)
      expect(response).to have_http_status(:not_found)
      expect(challenge.reload.voting_round).to eq(1)

      post reset_admin_challenge_path(challenge)
      expect(response).to have_http_status(:not_found)
      expect(challenge.reload.status).to eq(Challenge::Status::VOTING)
    end

    it "does not list the challenge" do
      get admin_challenges_path
      expect(response.body).not_to include(challenge.external_id)
    end
  end

  context "when logged in as the owner" do
    before { log_in_as(owner) }

    it "can manage the challenge" do
      post open_voting_admin_challenge_path(challenge)
      expect(response).to redirect_to(admin_challenges_path(anchor: "challenge-#{challenge.external_id}"))
      expect(challenge.reload.status).to eq(Challenge::Status::VOTING)
    end
  end

  context "when not logged in" do
    it "redirects to the home page" do
      get admin_challenges_path
      expect(response).to redirect_to("/")
    end

    it "cannot act on a challenge" do
      post open_voting_admin_challenge_path(challenge)

      expect(response).to redirect_to("/")
      expect(challenge.reload.status).to eq(Challenge::Status::OPEN)
    end
  end

  context "when the session refers to an administrator that no longer exists" do
    it "is treated as logged out" do
      log_in_as(owner)
      owner.destroy

      get admin_challenges_path
      expect(response).to redirect_to("/")

      get admin_challenges_path
      expect(response).to redirect_to("/")
    end
  end
end
