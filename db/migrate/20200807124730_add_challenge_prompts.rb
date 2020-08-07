class AddChallengePrompts < ActiveRecord::Migration[6.0]
  def up
    rename_column :challenges, :challenge_text, :challenge_context
    add_column :challenges, :challenge_prompt, :string
    execute "UPDATE challenges set challenge_prompt='If you were ten times bolder, what big idea would you recommend?'"
    add_column :challenges, :first_step_prompt, :string
    execute "UPDATE challenges set first_step_prompt='What first step would you take to get started?'"
  end

  def down
    remove_column :challenges, :challenge_prompt
    remove_column :challenges, :first_step_prompt
    rename_column :challenges, :challenge_context, :challenge_text
  end
end
