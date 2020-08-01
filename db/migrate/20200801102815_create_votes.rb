class CreateVotes < ActiveRecord::Migration[6.0]
  def change
    create_table :votes do |t|
      t.int :challenge_id
      t.int :proposed_solution_id
      t.int :participant_id
      t.int :vote

      t.timestamps
    end
  end
end
