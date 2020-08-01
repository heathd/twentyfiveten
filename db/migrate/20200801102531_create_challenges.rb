class CreateChallenges < ActiveRecord::Migration[6.0]
  def change
    create_table :challenges do |t|
      t.string :external_id
      t.string :challenge_text
      t.string :status

      t.timestamps
    end
  end
end
