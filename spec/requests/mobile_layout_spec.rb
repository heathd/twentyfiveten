require 'rails_helper'

# Participants will often be on phones, so the markup must let a phone lay the
# page out properly. The actual styling can't be asserted here, but these are
# the things it depends on.
RSpec.describe "Mobile friendly markup", type: :request do
  let(:administrator) { Administrator.create! }
  let!(:challenge)    { Challenge.create!(administrator: administrator, challenge_prompt: "A") }

  describe "every page" do
    it "tells phones to use the device width instead of a scaled-down desktop layout" do
      get root_path
      expect(response.body).to include('<meta name="viewport" content="width=device-width, initial-scale=1">')

      get challenge_path(challenge)
      expect(response.body).to include('<meta name="viewport" content="width=device-width, initial-scale=1">')
    end

    it "declares its language and a meaningful title" do
      get root_path

      expect(response.body).to include('<html lang="en">')
      expect(response.body).to include("<title>25/10 Crowdsourcing</title>")
    end
  end

  describe "the page structure" do
    # a method, not let: it must re-read the response after each request
    def page
      Nokogiri::HTML(response.body)
    end

    it "has a header with the app name, a main area and a footer" do
      get root_path

      expect(page.at_css("body > header.container nav a.brand")&.text).to eq("25/10 Crowdsourcing")
      expect(page.at_css("body > main.container")).to be_present
      expect(page.at_css("body > footer.container")).to be_present
    end

    it "links to the administrator's challenges only when logged in as one" do
      get root_path
      expect(page.css("body > header a").map(&:text)).not_to include("My challenges")

      post administrators_path
      get root_path
      expect(page.css("body > header a").map(&:text)).to include("My challenges")
    end

    it "shows the message from the previous action once, in a status region" do
      post login_administrators_path, params: { administrator_id: administrator.administrator_id }
      follow_redirect!

      notices = page.css("main .notice")
      expect(notices.size).to eq(1)
      expect(notices.first["role"]).to eq("status")
      expect(notices.first.text).to eq("Logged in successfully")
    end

    it "shows no empty message area when there is nothing to say" do
      get root_path

      expect(page.css(".notice")).to be_empty
      expect(page.css("#notice")).to be_empty
    end
  end

  describe "the voting page" do
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

    # a method, not let: it must re-read the response after each request
    def page
      Nokogiri::HTML(response.body)
    end

    it "shows the five scores as one labelled group of buttons" do
      get challenge_path(challenge)

      group = page.at_css('.vote-buttons[role="group"]')
      expect(group).to be_present
      expect(group["aria-label"]).to match(/1.*5/)
      expect(group.css('input[type="submit"]').map { |b| b["value"] }).to eq(%w[1 2 3 4 5])
    end

    it "submits the chosen score with each button" do
      get challenge_path(challenge)

      scores = page.css('.vote-buttons form').map { |f| f.at_css('input[type="hidden"][name="vote[vote]"]')["value"] }
      expect(scores).to eq(%w[1 2 3 4 5])
    end

    it "has no duplicate element ids (the five forms used to repeat them)" do
      get challenge_path(challenge)

      ids = page.css("[id]").map { |e| e["id"] }
      expect(ids.tally.select { |_id, count| count > 1 }).to be_empty
    end

    it "marks the score already cast when amending a vote" do
      vote = me.votes.find_by!(round: 1)
      vote.update!(vote: 4)

      get challenge_path(challenge, amend_vote: "1")

      selected = page.css('.vote-buttons input.selected')
      expect(selected.map { |b| b["value"] }).to eq(%w[4])
      expect(selected.first["aria-pressed"]).to eq("true")
    end

    it "marks nothing as selected before a score has been cast" do
      get challenge_path(challenge)

      expect(page.css('.vote-buttons input.selected')).to be_empty
    end
  end

  describe "the admin challenge list" do
    it "marks Reset and Delete as dangerous and asks for confirmation through data attributes, not inline handlers" do
      post login_administrators_path, params: { administrator_id: administrator.administrator_id }
      challenge.update!(status: Challenge::Status::VOTING, voting_round: 1)

      get admin_challenges_path
      page = Nokogiri::HTML(response.body)

      %w[Reset Delete].each do |label|
        button = page.at_css(%(input[type="submit"][value="#{label}"]))
        expect(button["class"]).to include("danger")
        expect(button["data-confirm"]).to be_present
        expect(button["onclick"]).to be_nil
      end
    end

    it "can scroll sideways on a narrow screen instead of overflowing the page" do
      post login_administrators_path, params: { administrator_id: administrator.administrator_id }

      get admin_challenges_path

      expect(Nokogiri::HTML(response.body).at_css(".table-scroll table.admin_challenge_index")).to be_present
    end
  end
end
