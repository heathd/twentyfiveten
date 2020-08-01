require 'securerandom'

class Challenge < ApplicationRecord
  has_many :participants
  has_many :proposed_solutions
  has_many :votes

  before_create do
    self.external_id = random_id(10) if external_id.blank?
    self.admin_id = random_id(14) if admin_id.blank?
    self.status = "open"
  end

  def random_id(length)
    SecureRandom.alphanumeric(length)
  end

  def to_param
    external_id
  end

  def votes_cast_this_round
    self.votes.where(round: self.voting_round).where.not(vote: nil).count
  end

  def open_voting!
    transaction do
      self.status = "voting"
      self.voting_round = 1
      schedule_votes!
      save!
    end
  end

  def next_round!
    if self.voting_round == 5
      self.status = "finished"
      self.voting_round = nil
    else
      self.voting_round += 1
    end
    save!
  end

  def schedule_votes!
    solution_participant_pairs = proposed_solutions.map {|sln| [sln.id, sln.participant_id] }

    (1..5).each do |round|
      solution_participant_pairs.each.with_index do |(proposed_solution_id, participant_id), i|
        index_to_use = (i + round) % solution_participant_pairs.size
        solution_to_vote_on = solution_participant_pairs[index_to_use][0]
        Vote.create!(
          challenge_id: self.id,
          participant_id: participant_id,
          round: round,
          proposed_solution_id: solution_to_vote_on
        )
      end
    end

  end
end
