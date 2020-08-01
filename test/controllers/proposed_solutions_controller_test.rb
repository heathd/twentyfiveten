require 'test_helper'

class ProposedSolutionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @proposed_solution = proposed_solutions(:one)
  end

  test "should get index" do
    get proposed_solutions_url
    assert_response :success
  end

  test "should get new" do
    get new_proposed_solution_url
    assert_response :success
  end

  test "should create proposed_solution" do
    assert_difference('ProposedSolution.count') do
      post proposed_solutions_url, params: { proposed_solution: { challenge_id: @proposed_solution.challenge_id, first_step: @proposed_solution.first_step, narrative: @proposed_solution.narrative } }
    end

    assert_redirected_to proposed_solution_url(ProposedSolution.last)
  end

  test "should show proposed_solution" do
    get proposed_solution_url(@proposed_solution)
    assert_response :success
  end

  test "should get edit" do
    get edit_proposed_solution_url(@proposed_solution)
    assert_response :success
  end

  test "should update proposed_solution" do
    patch proposed_solution_url(@proposed_solution), params: { proposed_solution: { challenge_id: @proposed_solution.challenge_id, first_step: @proposed_solution.first_step, narrative: @proposed_solution.narrative } }
    assert_redirected_to proposed_solution_url(@proposed_solution)
  end

  test "should destroy proposed_solution" do
    assert_difference('ProposedSolution.count', -1) do
      delete proposed_solution_url(@proposed_solution)
    end

    assert_redirected_to proposed_solutions_url
  end
end
