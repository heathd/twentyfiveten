# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_03_07_195547) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "administrators", force: :cascade do |t|
    t.string "administrator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["administrator_id"], name: "index_administrators_on_administrator_id"
  end

  create_table "challenges", force: :cascade do |t|
    t.integer "administrator_id"
    t.string "external_id"
    t.string "admin_id"
    t.string "challenge_context"
    t.string "status"
    t.integer "voting_round"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "challenge_prompt"
    t.string "first_step_prompt"
    t.index ["administrator_id"], name: "index_challenges_on_administrator_id"
  end

  create_table "participants", force: :cascade do |t|
    t.integer "challenge_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "consent"
    t.index ["challenge_id"], name: "index_participants_on_challenge_id"
  end

  create_table "proposed_solutions", force: :cascade do |t|
    t.integer "challenge_id"
    t.integer "participant_id"
    t.string "narrative"
    t.string "first_step"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_proposed_solutions_on_challenge_id"
    t.index ["participant_id"], name: "index_proposed_solutions_on_participant_id"
  end

  create_table "votes", force: :cascade do |t|
    t.integer "challenge_id"
    t.integer "proposed_solution_id"
    t.integer "participant_id"
    t.integer "vote"
    t.integer "round"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_votes_on_challenge_id"
    t.index ["participant_id"], name: "index_votes_on_participant_id"
    t.index ["proposed_solution_id"], name: "index_votes_on_proposed_solution_id"
    t.index ["round"], name: "index_votes_on_round"
  end

end
