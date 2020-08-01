class Vote < ApplicationRecord
  belongs_to :participant
  belongs_to :proposed_solution
end
