require 'test_helper'

class ChallengesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @challenge = challenges(:one)
  end

  test "should show challenge" do
    get challenge_url(@challenge)
    assert_response :success
  end
end
