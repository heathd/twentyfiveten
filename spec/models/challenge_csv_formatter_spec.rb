require 'rails_helper'
require 'challenge_csv_formatter'

RSpec.describe("ChallengeCsvFormatter", type: :model) do
  it "exists" do
    c = Challenge.create!(
      challenge_context: "Our company transformation",
      challenge_prompt: "What is your bold idea for ensuring we remain competitive?",
      first_step_prompt: "What's the first step?",
      administrator: Administrator.new
    )
    p1 = Participant.create!(challenge_id: c.id, consent: true)
    p1.create_proposed_solution!(challenge_id: c.id, narrative: "Fire the executive team", first_step: "Convince the board")
    p2 = Participant.create!(challenge_id: c.id, consent: true)
    p2.create_proposed_solution!(challenge_id: c.id, narrative: "Give all employees permission to spend up to $10k\non an efficiency initiatve", first_step: "Put a proposal together")

    c.schedule_votes!

    p1.votes.each do |v|
      v.update!(vote: 4)
    end

    p2.votes.take(4).each do |v|
      v.update!(vote: 4)
    end

    f = ChallengeCsvFormatter.new(c, host: "only.for.testing")

    generated_csv = f.to_csv

    expect(generated_csv).to start_with("\uFEFF")

    data = CSV.parse(generated_csv[1..-1])

    results_index = data.find_index {|row| row.first =~ /RESULTS/}

    hash = Hash[data.select {|r| r.size == 2}]
    expect(hash).to include("Challenge ID" => c.external_id)
    expect(hash).to include("Challenge URL" => "http://only.for.testing/challenges/#{c.external_id}")
    expect(hash).to include("Date challenge created" => c.created_at.to_s)
  end
end
