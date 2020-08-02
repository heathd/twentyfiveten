class AddIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index :administrators, :administrator_id
    add_index :proposed_solutions, :challenge_id
    add_index :proposed_solutions, :participant_id
    add_index :participants, :challenge_id
    add_index :challenges, :administrator_id
    add_index :votes, :challenge_id
    add_index :votes, :proposed_solution_id
    add_index :votes, :participant_id
    add_index :votes, :round
  end
end
