class AddChallengeType < ActiveRecord::Migration[6.0]
  def down
    remove_column :challenges, :challenge_type, :string
  end

  def up
    add_column :challenges, :challenge_type, :string
  end
end
