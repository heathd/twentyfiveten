module Admin::ChallengesHelper
  # The id of a challenge's card in the administrator's list. Redirecting to #<this id> after an
  # action scrolls the browser so that the card is at the top of the screen.
  def challenge_card_id(challenge)
    "challenge-#{challenge.external_id}"
  end
end
