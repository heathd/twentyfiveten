json.extract! vote, :id, :challenge_id, :proposed_solution_id, :participant_id, :vote, :created_at, :updated_at
json.url vote_url(vote, format: :json)
