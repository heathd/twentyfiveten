require 'rails_helper'

# The administrator's list of challenges: one card per challenge, readable on a phone, with
# the share link and the actions that make sense for the challenge's current state.
RSpec.describe "Admin challenge list", type: :request do
  let(:administrator) { Administrator.create! }

  def page
    Nokogiri::HTML(response.body)
  end

  def card_for(challenge)
    page.at_css(%(article.admin-challenge[data-challenge-id="#{challenge.external_id}"]))
  end

  def buttons_in(card)
    card.css('input[type="submit"]').map { |b| b["value"] }
  end

  def link_texts_in(card)
    card.css("a").map { |a| a.text.strip }
  end

  before do
    post login_administrators_path, params: { administrator_id: administrator.administrator_id }
  end

  def add_participants(challenge, count)
    count.times do |i|
      participant = Participant.create!(challenge_id: challenge.id, consent: true)
      ProposedSolution.create!(challenge_id: challenge.id, participant_id: participant.id, narrative: "idea #{i}", first_step: "s")
    end
  end

  describe "with no challenges" do
    it "says so and offers to create one" do
      get admin_challenges_path

      expect(page.css("article.admin-challenge")).to be_empty
      expect(page.at_css(".admin-challenges").text).to include("No challenges yet")
      expect(page.css("a[role=button]").map(&:text)).to include("New challenge")
    end
  end

  describe "a card" do
    let!(:challenge) do
      Challenge.create!(administrator: administrator, challenge_prompt: "What would you change?",
                        challenge_context: "Some context for the group")
    end

    it "shows the prompt, the context and the full link to share" do
      get admin_challenges_path
      card = card_for(challenge)

      expect(card.text).to include("What would you change?")
      expect(card.text).to include("Some context for the group")
      # the whole URL, as text, so it can be read and copied on a phone
      expect(card.text).to include("http://www.example.com/challenges/#{challenge.external_id}")
      expect(card.at_css(%(a[href="/challenges/#{challenge.external_id}"]))).to be_present
    end

    it "links to edit and view the challenge" do
      get admin_challenges_path
      links = card_for(challenge).css("a").to_h { |a| [a.text.strip, a["href"]] }

      expect(links["Edit"]).to eq(edit_admin_challenge_path(challenge))
      expect(links["View"]).to eq(challenge_path(challenge))
    end

    it "has a dangerous, confirmed Delete button, without inline handlers" do
      get admin_challenges_path
      delete_button = card_for(challenge).at_css('input[type="submit"][value="Delete"]')

      expect(delete_button["class"]).to include("danger")
      expect(delete_button["data-confirm"]).to be_present
      expect(delete_button["onclick"]).to be_nil
    end

    it "is a card, not a table row, so it fits a narrow screen" do
      get admin_challenges_path

      expect(page.css("table")).to be_empty
      expect(page.css(".admin-challenges article.admin-challenge").size).to eq(1)
    end
  end

  describe "an open challenge" do
    let!(:challenge) { Challenge.create!(administrator: administrator, challenge_prompt: "Open one") }

    before { add_participants(challenge, 3) }

    it "shows the status and the counts, and offers to open voting" do
      get admin_challenges_path
      card = card_for(challenge)

      expect(card.at_css(".status.status-open").text).to eq("Waiting for participants")
      expect(card.text).to include("3 participants")
      expect(card.text).to include("3 proposals")
      expect(buttons_in(card)).to include("Open voting")
      expect(buttons_in(card)).not_to include("Next round", "Reset", "Conclude voting")
    end

    it "counts participants who have not submitted an idea separately" do
      Participant.create!(challenge_id: challenge.id, consent: true)

      get admin_challenges_path

      expect(card_for(challenge).text).to include("4 participants")
      expect(card_for(challenge).text).to include("3 proposals")
    end
  end

  describe "a challenge that is voting" do
    let!(:challenge) { Challenge.create!(administrator: administrator, challenge_prompt: "Voting one") }

    before do
      add_participants(challenge, 7)
      challenge.open_voting!
    end

    it "shows the round, a progress bar, and the votes cast this round" do
      challenge.next_round!
      vote = challenge.votes.find_by!(round: 2)
      vote.update!(vote: 4)

      get admin_challenges_path
      card = card_for(challenge)

      expect(card.at_css(".status.status-voting").text).to eq("Voting")
      expect(card.text).to include("Round 2 of 5")
      expect(card.at_css("progress")["value"]).to eq("2")
      expect(card.at_css("progress")["max"]).to eq("5")
      expect(card.text).to include("Votes cast: 1 / 7")
    end

    it "offers Next round and Reset before the final round" do
      get admin_challenges_path

      expect(buttons_in(card_for(challenge))).to include("Next round", "Reset")
      expect(buttons_in(card_for(challenge))).not_to include("Conclude voting", "Open voting")
    end

    it "gives Reset a dangerous style and a confirmation" do
      get admin_challenges_path
      reset = card_for(challenge).at_css('input[type="submit"][value="Reset"]')

      expect(reset["class"]).to include("danger")
      expect(reset["data-confirm"]).to match(/cancel all votes/)
      expect(reset["onclick"]).to be_nil
    end

    it "offers Conclude voting, and no Reset, on the final round" do
      4.times { challenge.next_round! }

      get admin_challenges_path
      card = card_for(challenge)

      expect(card.text).to include("Round 5 of 5")
      expect(buttons_in(card)).to include("Conclude voting")
      expect(buttons_in(card)).not_to include("Next round", "Reset")
    end
  end

  describe "a finished challenge" do
    let!(:challenge) { Challenge.create!(administrator: administrator, challenge_prompt: "Done one") }

    before do
      add_participants(challenge, 7)
      challenge.open_voting!
      5.times { challenge.next_round! }
    end

    it "links to the results and the CSV, and offers no voting buttons" do
      get admin_challenges_path
      card = card_for(challenge)

      expect(card.at_css(".status.status-finished").text).to eq("Finished")
      expect(link_texts_in(card)).to include("See results", "Download CSV")
      expect(card.at_css(%(a[href="#{challenge_path(challenge, format: :csv)}"]))).to be_present
      expect(buttons_in(card)).to eq(["Delete"])
    end
  end

  describe "how old a challenge is" do
    let!(:fresh) { Challenge.create!(administrator: administrator, challenge_prompt: "Fresh") }
    let!(:old)   { Challenge.create!(administrator: administrator, challenge_prompt: "Old", created_at: 21.days.ago) }
    let!(:stale) { Challenge.create!(administrator: administrator, challenge_prompt: "Stale", created_at: 29.days.ago) }

    it "says in words, not only in colour, when data is about to be deleted" do
      get admin_challenges_path

      expect(card_for(fresh).css(".age-note")).to be_empty
      expect(card_for(old).at_css(".age-note").text).to include("older than 20 days")
      expect(card_for(stale).at_css(".age-note").text).to include("deleted soon")
    end

    it "marks the card with the age class too" do
      get admin_challenges_path

      expect(card_for(old)["class"]).to include("old")
      expect(card_for(stale)["class"]).to include("about_to_be_deleted")
      expect(card_for(fresh)["class"]).not_to include("old")
    end

    it "shows how long ago it was created" do
      get admin_challenges_path

      expect(card_for(old).text).to match(/Created .*ago/)
    end
  end

  describe "ordering and ownership" do
    it "lists the newest first, and only this administrator's challenges" do
      older  = Challenge.create!(administrator: administrator, challenge_prompt: "Older", created_at: 2.days.ago)
      newer  = Challenge.create!(administrator: administrator, challenge_prompt: "Newer")
      others = Challenge.create!(administrator: Administrator.create!, challenge_prompt: "Not mine")

      get admin_challenges_path

      ids = page.css("article.admin-challenge").map { |c| c["data-challenge-id"] }
      expect(ids).to eq([newer.external_id, older.external_id])
      expect(ids).not_to include(others.external_id)
    end
  end

  describe "the notes under the list" do
    it "still shows the retention warning and the administrator's login code" do
      get admin_challenges_path

      expect(response.body).to include("Data will be deleted after 30 days")
      expect(response.body).to include(administrator.administrator_id)
    end
  end
end
