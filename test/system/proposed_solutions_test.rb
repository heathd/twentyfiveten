require "application_system_test_case"

class ProposedSolutionsTest < ApplicationSystemTestCase
  setup do
    @proposed_solution = proposed_solutions(:one)
  end

  test "visiting the index" do
    visit proposed_solutions_url
    assert_selector "h1", text: "Proposed Solutions"
  end

  test "creating a Proposed solution" do
    visit proposed_solutions_url
    click_on "New Proposed Solution"

    fill_in "Challenge", with: @proposed_solution.challenge_id
    fill_in "First step", with: @proposed_solution.first_step
    fill_in "Narrative", with: @proposed_solution.narrative
    click_on "Create Proposed solution"

    assert_text "Proposed solution was successfully created"
    click_on "Back"
  end

  test "updating a Proposed solution" do
    visit proposed_solutions_url
    click_on "Edit", match: :first

    fill_in "Challenge", with: @proposed_solution.challenge_id
    fill_in "First step", with: @proposed_solution.first_step
    fill_in "Narrative", with: @proposed_solution.narrative
    click_on "Update Proposed solution"

    assert_text "Proposed solution was successfully updated"
    click_on "Back"
  end

  test "destroying a Proposed solution" do
    visit proposed_solutions_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Proposed solution was successfully destroyed"
  end
end
