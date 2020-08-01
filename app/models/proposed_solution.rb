class ProposedSolution < ApplicationRecord
  has_many :votes

  def total_score
    @total_score ||= calculate_total_score
  end

  def calculate_total_score
    all_votes = self.votes.map {|v| v.vote}.compact
    if all_votes.size == 0
      0
    else
      all_votes.sum * 5 / all_votes.size
    end
  end
end
