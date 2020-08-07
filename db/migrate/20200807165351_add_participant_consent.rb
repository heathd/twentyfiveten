class AddParticipantConsent < ActiveRecord::Migration[6.0]
  def up
    add_column :participants, :consent, :boolean
    execute "update participants set consent='t'"
  end

  def down
    remove_column :participants, :consent
  end
end
