class CreateProposedSolutions < ActiveRecord::Migration[6.0]
  def change
    create_table :proposed_solutions do |t|
      t.int :challenge_id
      t.string :narrative
      t.string :first_step

      t.timestamps
    end
  end
end
