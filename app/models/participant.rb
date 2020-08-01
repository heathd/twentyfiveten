require 'securerandom'

class Participant < ApplicationRecord
  belongs_to :challenge
  has_one :proposed_solution
  has_many :votes
end
