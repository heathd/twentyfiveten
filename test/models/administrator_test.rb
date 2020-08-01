require 'test_helper'

class AdministratorTest < ActiveSupport::TestCase
  test "creates random administrator id on creation" do
    c = Administrator.new
    c.save!
    assert_match /^[a-zA-Z0-9]{14}$/, c.administrator_id
  end
end
