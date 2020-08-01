class CreateChallenges < ActiveRecord::Migration[6.0]
  def change
    create_table :challenges do |t|
      t.integer :administrator_id
      t.string :external_id
      t.string :admin_id
      t.string :challenge_text
      t.string :status
      t.integer :voting_round

      t.timestamps
    end
  end
end
