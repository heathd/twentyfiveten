require 'csv'

class ChallengeCsvFormatter
  attr_reader :challenge, :host

  def initialize(challenge, host:)
    @challenge = challenge
    @host = host
  end

  def to_csv
    CSV.generate("\uFEFF") do |csv|
      csv << ["Challenge ID", challenge.external_id]
      csv << ["Challenge URL", challenge_url(challenge)]
      csv << ["Date challenge created", challenge.created_at.to_s]
      csv << ["Context", challenge.challenge_context] if challenge.challenge_context.present?
      csv << ["Prompt", challenge.challenge_prompt] if challenge.challenge_prompt.present?
      csv << ["First step prompt", challenge.first_step_prompt] if challenge.first_step_prompt.present?
      csv << []
      csv << ["Number of participants", challenge.number_of_participants]
      csv << ["Number of proposals", challenge.number_of_proposals]
      csv << ["Number of votes cast", challenge.number_of_votes_cast]
      csv << []
      csv << ["==== RESULTS ====="]

      csv << ["Total score", "Proposed solution", "First step", "Number of votes"] + (1..5).map {|n| "Round #{n}"}
      challenge.results.each do |proposed_solution|
        csv << [
          proposed_solution.total_score,
          proposed_solution.narrative,
          proposed_solution.first_step,
          proposed_solution.votes.map(&:vote).compact.size
        ] + proposed_solution.votes.map(&:vote)
      end
    end
  end

  def challenge_url(challenge)
    Rails.application.routes.url_helpers.challenge_url(challenge, host: host)
  end
end

