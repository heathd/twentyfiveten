require 'securerandom'

class Participant < ApplicationRecord
  belongs_to :challenge
  has_one :proposed_solution
  has_many :votes

  validates_presence_of :consent, message: "To use this app, you must consent to data processing"
end
