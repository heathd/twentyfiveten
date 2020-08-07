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
      Participant.create!(challenge_id: c.id)
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
      Participant.create!(challenge_id: c.id)
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

end
