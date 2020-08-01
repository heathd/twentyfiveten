require 'test_helper'

class ChallengeTest < ActiveSupport::TestCase
  test "creates random external id on creation" do
    c = Challenge.new(challenge_text: "Foo")
    c.save!
    assert_match /^[a-zA-Z0-9]{10}$/, c.external_id
    assert_match /^[a-zA-Z0-9]{14}$/, c.admin_id
  end

  test "schedules votes" do
    c = Challenge.create!(challenge_text: "Foo")
    (1..20).each do
      Participant.create!(challenge_id: c.id)
    end
    c.participants.each do |p|
      p.create_proposed_solution!(challenge_id: c.id, narrative: "a", first_step: "b")
    end

    assert_equal 20, c.participants.count
    assert_equal 20, c.proposed_solutions.count

    c.schedule_votes!

    # byebug
    first_participant = c.participants.first
    assert_equal c.id, first_participant.votes.first.challenge_id
    assert_equal 5, first_participant.votes.count
    assert_equal (1..5).to_a, first_participant.votes.map {|v| v.round}.sort

    assert first_participant.votes.first.proposed_solution.persisted?

    assert c.participants.map { |p| p.votes.count }.all? {|c| c == 5}, "all participants have five votes"
    assert c.participants.map { |p| p.votes.map {|v| v.round}.sort }.all? {|rounds| rounds == (1..5).to_a}, "over five rounds"
  end

end
