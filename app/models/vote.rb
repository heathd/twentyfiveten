class Vote < ApplicationRecord
  belongs_to :participant
  belongs_to :proposed_solution

  # Votes are created unscored (nil) when voting opens. Once a score is cast it
  # must be 1 to 5 and cannot be cleared again.
  validates :vote, inclusion: { in: 1..5 }, unless: -> { vote.nil? && vote_was.nil? }
end
