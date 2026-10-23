require 'rails_helper'

RSpec.describe "Challenge", type: :model do
  it "creates random external id on creation" do
    c = Challenge.new(challenge_prompt: "Foo", administrator: Administrator.new)
    c.save!
    assert_match /^[a-zA-Z0-9]{10}$/, c.external_id
    assert_match /^[a-zA-Z0-9]{14}$/, c.admin_id
  end

  it "schedules votes" do
    c = Challenge.create!(challenge_prompt: "Foo", administrator: Administrator.new)
    (1..20).each do
      Participant.create!(challenge_id: c.id, consent: true)
    end
    c.participants.each do |p|
      p.create_proposed_solution!(challenge_id: c.id, narrative: "a", first_step: "b")
    end

    expect(c.participants.count).to eq(20)
    expect(c.proposed_solutions.count).to eq(20)

    c.schedule_votes!

    # byebug
    first_participant = c.participants.first
    expect(first_participant.votes.first.challenge_id).to eq(c.id)
    expect(first_participant.votes.count).to eq(5)
    expect(first_participant.votes.map {|v| v.round}.sort).to eq((1..5).to_a)

    expect(first_participant.votes.first.proposed_solution.persisted?).to be_truthy

    expect(c.participants.map { |p| p.votes.count }.all? {|c| c == 5}).to be_truthy
    expect(c.participants.map { |p| p.votes.map {|v| v.round}.sort }.all? {|rounds| rounds == (1..5).to_a}).to be_truthy
    c.participants.each do |p|
      expect(p.votes.map {|v| v.proposed_solution.id }.uniq.size).to eq(5)
      expect(p.votes.map {|v| v.proposed_solution.id }.include?(p.proposed_solution.id)).to be_falsey
    end
  end

  it "reset" do
    c = Challenge.create!(challenge_prompt: "Foo", administrator: Administrator.new)
    (1..5).each do
      Participant.create!(challenge_id: c.id, consent: true)
    end
    c.participants.each do |p|
      p.create_proposed_solution!(challenge_id: c.id, narrative: "a", first_step: "b")
    end

    c.schedule_votes!
    expect(c.participants.first.votes.count).to eq(5)

    c.reset!

    expect(c.status).to eq("open")
    expect(c.participants.first.votes.count).to eq(0)
  end

  describe "lifecycle transitions" do
    let(:challenge) { Challenge.create!(challenge_prompt: "Foo", administrator: Administrator.new) }

    before do
      6.times do |i|
        participant = Participant.create!(challenge_id: challenge.id, consent: true)
        participant.create_proposed_solution!(challenge_id: challenge.id, narrative: "idea #{i}", first_step: "s")
      end
    end

    it "only opens voting on an open challenge" do
      challenge.open_voting!
      expect { challenge.open_voting! }.to raise_error(Challenge::InvalidTransition)

      4.times { challenge.next_round! }
      challenge.next_round!
      expect(challenge.status).to eq(Challenge::Status::FINISHED)
      expect { challenge.open_voting! }.to raise_error(Challenge::InvalidTransition)
    end

    it "only advances rounds while voting" do
      expect { challenge.next_round! }.to raise_error(Challenge::InvalidTransition)

      challenge.open_voting!
      5.times { challenge.next_round! }
      expect { challenge.next_round! }.to raise_error(Challenge::InvalidTransition)
    end

    it "leaves the challenge untouched when a transition is refused" do
      challenge.open_voting!
      votes = challenge.votes.count

      expect { challenge.open_voting! }.to raise_error(Challenge::InvalidTransition)

      challenge.reload
      expect(challenge.voting_round).to eq(1)
      expect(challenge.votes.count).to eq(votes)
    end

    it "checks the state in the database, not a stale copy (two requests at once)" do
      stale = Challenge.find(challenge.id)
      expect(stale.status).to eq(Challenge::Status::OPEN)

      challenge.open_voting!

      expect { stale.open_voting! }.to raise_error(Challenge::InvalidTransition)
      expect(challenge.votes.count).to eq(6 * 5)
    end

    it "reset clears the round" do
      challenge.open_voting!
      challenge.next_round!

      challenge.reset!

      expect(challenge.status).to eq(Challenge::Status::OPEN)
      expect(challenge.voting_round).to be_nil
    end
  end

end
