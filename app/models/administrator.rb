require 'securerandom'

class Administrator < ApplicationRecord

  before_create do
    self.administrator_id = random_id(14) if administrator_id.blank?
  end

  def random_id(length)
    SecureRandom.alphanumeric(length)
  end
end
