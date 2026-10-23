# Architecture

## Purpose

Twenty Five Ten is a small web app that runs the **25/10 Crowd Sourcing** Liberating Structure online. A facilitator poses a prompt ("If you were ten times bolder, what big idea would you recommend?"). Each participant submits one idea plus a first step. The ideas are then scored anonymously over five rounds, with each participant scoring a different idea in each round (1–5). Ideas are ranked by score at the end.

It is deliberately minimal and privacy-conscious:

- Nobody logs in with a name or password. Identity is a random token held in the session cookie.
- Data is short-lived. A scheduled job deletes everything older than 30 days.
- It runs on Heroku, and can be self-hosted.

## Technology stack

| Concern | Choice |
|---|---|
| Framework | Rails 7.1 (Ruby version pinned in `.ruby-version`) |
| Database | PostgreSQL (`pg`) |
| Server | Puma |
| Frontend | Server-rendered ERB, Sprockets and Sass, and the Skeleton CSS grid (`skeleton-rails`). There is no JS framework: Turbo, Stimulus and Tailwind are commented out in the Gemfile. |
| Tests | RSpec, with Capybara, Timecop and database_cleaner available |
| CI | GitHub Actions with Postgres 14 (`.github/workflows/ruby.yml`) |
| Deploy | Heroku (Postgres, plus the Scheduler add-on for `expunge_data`) |

## Domain model

```
Administrator 1─* Challenge 1─* Participant 1─1 ProposedSolution
                      │              │                │
                      └──────────────┴───* Vote *─────┘
```

Tables are in `db/schema.rb`. The models are in `app/models/`.

- **Administrator** has only a random 14-character `administrator_id`, which works as a bearer credential. It is generated in a `before_create` hook.
- **Challenge** is the central aggregate.
  - `external_id` is a random 10-character public ID, used as the URL param via `to_param`.
  - `status` is one of `open`, `voting` or `finished` (`Challenge::Status`).
  - `voting_round` is 1–5 while voting.
  - It has three text fields: context, prompt and first-step prompt.
  - It owns the workflow state machine (see below).
- **Participant** is an anonymous attendee of one challenge. It stores only the `consent` flag, which is required.
- **ProposedSolution** has a `narrative` and a `first_step`. `total_score` is `sum(votes) * 5 / count(votes)`, ignoring unvoted rows. It normalises scores to a 25-point scale, so an idea that received fewer votes is not penalised.
- **Vote** is one participant's score (`vote`, nullable until cast) for one proposed solution in one `round`. The rows are pre-created when voting opens.

## Challenge lifecycle

The state machine lives in `Challenge` (`app/models/challenge.rb`) and is driven by the admin controller.

```
open ──open_voting!──▶ voting (round 1) ──next_round! ×4──▶ round 5 ──next_round!──▶ finished
  ▲                        │
  └────────── reset! ──────┘   (destroys all votes)
```

1. **open**: participants register (consent) and submit or edit their idea.
2. **`open_voting!`**: in one transaction, status is set to `voting`, round to 1, and `schedule_votes!` runs.
3. **`schedule_votes!`** is the core algorithm. Solutions are indexed in a list. For each round `r` in 1..5, the participant at position `i` is assigned the solution at position `(i + r) % n`. This is a rotating Latin-square-style assignment, so:
   - each participant scores 5 different ideas, one per round;
   - nobody scores their own idea (offsets 1–5 never wrap to self, as long as `n` is greater than 5);
   - each idea receives roughly 5 votes.
   `spec/models/challenge_spec.rb` checks these properties.
4. **`next_round!`** increments the round. After round 5 the status becomes `finished` and `voting_round` is cleared.
5. **`reset!`** returns the challenge to `open` and destroys the votes.

## Request flow and access control

Routes are in `config/routes.rb`. There are three audiences, each using a different kind of credential.

**Administrator** (`/administrators`, `/admin/challenges`)
- `POST /administrators` creates an Administrator and stores its token in `session[:administrator_id]`.
- `login` and `logout` let an admin resume on another browser by pasting the token.
- `Admin::ChallengesController` has `before_action :require_administrator`. It scopes the index to the admin's own challenges and has the member actions `open_voting`, `next_round` and `reset`.

**Participant** (`/challenges/:id/...`)
- The `:id` is the public `external_id`. Anyone with the link can join.
- `ParticipantsController#create` records consent and stores `session[:participant_id]`. Joining is only allowed while the challenge is `open`.
- `ProposedSolutionsController` creates and edits the participant's idea. `participant_id` is taken from the session, not from params.
- `VotesController#update` lets a participant set the score on a pre-created vote. The lookup is scoped to `session[:participant_id]`.

**Viewing** (`ChallengesController#show`)
- `set_participant` loads the participant from the session, scoped to this challenge.
- `set_participation_state` yields `active` or `unregistered`. Late joiners, who have no votes scheduled once voting has started, count as unregistered.
- `show.html.erb` renders `challenges/participant/<participation_state>/<challenge_status>`. The state × status matrix of partials is how the UI changes through the lifecycle. For example, `active/_voting.html.erb` shows the current round's idea and the 1–5 buttons.
- `show.csv` exports the challenge, its counts, and the ranked results with per-round scores through `lib/challenge_csv_formatter.rb`.

**Home** (`HomeController`) serves the landing page and the privacy page, and validates the admin session.

## Data retention

`lib/tasks/scheduler.rake` defines `expunge_data`. The Heroku Scheduler runs it to delete Votes, ProposedSolutions, Participants and Challenges created more than 30 days ago. The UI reflects this: `Challenge#age_class` marks challenges as `old` after 20 days and `about_to_be_deleted` after 28. `spec/test/integration/expunge_data_rake_task_spec.rb` covers the task.

## Layout

```
app/controllers/        Public flow plus admin/challenges_controller.rb
app/models/             Administrator, Challenge (state machine), Participant, ProposedSolution, Vote
app/views/challenges/participant/{active,unregistered}/   Partials per participation state and challenge status
app/views/admin/challenges/                               Admin dashboard and forms
lib/challenge_csv_formatter.rb                            CSV export
lib/tasks/scheduler.rake                                  Data expunge job
spec/                                                     Model and rake task specs
docs/                                                     Screenshots referenced by README
```

## Notes and caveats

- Authorisation rests on unguessable random IDs and cookie sessions, not accounts. Anyone holding an administrator token has full admin rights.
- Several controllers (`ProposedSolutions`, `Participants`, `Votes`, `Administrators`) still contain Rails scaffold actions beyond what the routes expose. `ProposedSolutionsController` and `Administrators` have some actions that are routed but unused or unscoped, such as `index`, `destroy`, and `update` by raw ID, so they warrant review.
- `Challenge` has no database-level foreign keys or constraints. Integrity relies on the model code.
- `schedule_votes!` assumes more than 5 participants who have submitted a proposal. With fewer, a participant may be assigned their own idea or a duplicate.
- Test coverage is mainly at the model and rake level. There are no controller or system specs yet, although Capybara is installed.
