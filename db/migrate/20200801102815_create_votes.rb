class CreateVotes < ActiveRecord::Migration[6.0]
  def change
    create_table :votes do |t|
      t.integer :challenge_id
      t.integer :proposed_solution_id
      t.integer :participant_id
      t.integer :vote
      t.integer :round

      t.timestamps
    end
  end
end
