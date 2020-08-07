class DropChallengeType < ActiveRecord::Migration[6.0]
  def change
    remove_column :challenges, :challenge_type
  end
end
