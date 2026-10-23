# Architecture

## Purpose

Twenty Five Ten is a small web app that runs the **25/10 Crowd Sourcing** Liberating Structure online. A facilitator poses a prompt ("If you were ten times bolder, what big idea would you recommend?"). Each participant submits one idea plus a first step. The ideas are then scored anonymously over five rounds, with each participant scoring a different idea in each round (1–5). Ideas are ranked by score at the end.

It is deliberately minimal and privacy-conscious:

- Nobody logs in with a name or password. Identity is a random token held in the session cookie.
- Data is short-lived. A scheduled job deletes everything older than 30 days.
- It runs on Heroku at <https://twenty-five-ten.herokuapp.com/>.

## Technology stack

| Concern | Choice |
|---|---|
| Language | Ruby 3.3.13, pinned in the `Gemfile` and `.tool-versions` |
| Framework | Rails 8.1 (`~> 8.1.0`), `load_defaults 8.1` |
| Database | PostgreSQL (`pg`) |
| Server | Puma (`config/puma.rb`, 5 threads unless `RAILS_MAX_THREADS` is set) |
| Frontend | Server-rendered ERB and Sprockets/Sass. CSS is Skeleton 2.0.4 and normalize.css 8.0.1, vendored in `vendor/assets/stylesheets`. There is **no JavaScript**: the layout loads none, and Turbo, Stimulus and Tailwind are not used. |
| Tests | RSpec (request, model and rake specs), with Timecop and DatabaseCleaner |
| CI | `bin/ci` locally and in GitHub Actions (`.github/workflows/ruby.yml`), with Postgres 14 |
| Deploy | Heroku. `Procfile` runs `web` (Puma) and a `release` phase (`rails db:migrate`) |

## Domain model

```
Administrator 1─* Challenge 1─* Participant 1─1 ProposedSolution
                      │              │                │
                      └──────────────┴───* Vote *─────┘
```

Tables are in `db/schema.rb`. The models are in `app/models/`.

- **Administrator** has only a random 14-character `administrator_id`, which works as a bearer credential. It is generated in a `before_create` hook.
- **Challenge** is the central aggregate.
  - `external_id` is a random 10-character **public** ID, used as the URL param via `to_param`.
  - `status` is one of `open`, `voting` or `finished` (`Challenge::Status`).
  - `voting_round` is 1–5 while voting.
  - It has three text fields: context, prompt and first-step prompt.
  - It owns the workflow state machine (see below).
- **Participant** is an anonymous attendee of one challenge. It stores only the `consent` flag, which is required.
- **ProposedSolution** has a `narrative` and a `first_step`. `total_score` is `sum(votes) * 5 / count(votes)`, ignoring unvoted rows. It normalises scores to a 25-point scale, so an idea that received fewer votes is not penalised.
- **Vote** is one participant's score for one proposed solution in one `round`. The rows are pre-created, unscored, when voting opens. Once cast, a score must be 1–5 and cannot be cleared.

## Challenge lifecycle

The state machine lives in `Challenge` (`app/models/challenge.rb`) and is driven by the admin controller.

```
open ──open_voting!──▶ voting (round 1) ──next_round! ×4──▶ round 5 ──next_round!──▶ finished
  ▲                        │
  └────────── reset! ──────┘   (destroys all votes)
```

1. **open**: participants register (consent) and submit or edit their idea. This is the only state in which proposals can be created or changed.
2. **`open_voting!`**: in one transaction, status is set to `voting`, round to 1, and `schedule_votes!` runs.
3. **`schedule_votes!`** is the core algorithm. Solutions are indexed in a list. For each round `r` in 1..5, the participant at position `i` is assigned the solution at position `(i + r) % n`. This is a rotating Latin-square-style assignment, so:
   - each participant scores 5 different ideas, one per round;
   - nobody scores their own idea (offsets 1–5 never wrap to self, as long as `n` is greater than 5);
   - each idea receives roughly 5 votes.
   `spec/models/challenge_spec.rb` checks these properties.
4. **`next_round!`** increments the round. After round 5 the status becomes `finished` and `voting_round` is cleared.
5. **`reset!`** returns the challenge to `open` and destroys the votes.

`open_voting!` is only allowed from `open`, and `next_round!` only while `voting`; otherwise they raise `Challenge::InvalidTransition`, which the admin controller turns into a notice and a redirect. `reset!` is allowed from any state, and clears the voting round. Each transition takes a row lock (`with_lock`) and re-reads the challenge before checking its state, so a double click can't schedule the votes twice.

While voting, only the vote for the **current** round can be scored or amended. Earlier and later rounds, and any vote once the challenge is finished, are locked.

## Request flow and access control

Routes are in `config/routes.rb`. There are three audiences, each using a different kind of credential, and **every lookup is scoped to the credential's owner**. A record that belongs to someone else, or doesn't exist, is a 404.

| Audience | Credential | Controller and actions |
|---|---|---|
| Administrator | `session[:administrator_id]` (the token) | `AdministratorsController`: `create`, `login`, `logout`. `Admin::ChallengesController`: full CRUD plus `open_voting`, `next_round`, `reset` |
| Participant | `session[:participant_id]`, plus the public challenge `external_id` in the URL | `ParticipantsController#create`; `ProposedSolutionsController`: `create`, `update`; `VotesController#update` |
| Anyone with the link | none | `ChallengesController#show` (HTML and CSV), `HomeController` (landing and privacy pages) |

**Administrator**
- `POST /administrators` creates an Administrator and stores its token in the session. `login` lets an admin resume on another browser by pasting the token.
- `Admin::ChallengesController` has `before_action :require_administrator`, which checks the administrator record actually exists and clears a stale session. Every challenge lookup is scoped to the logged-in administrator. This matters because `external_id` is public: it is in the participant URL.

**Participant**
- `ParticipantsController#create` records consent and stores `session[:participant_id]`. Joining is only allowed while the challenge is `open`.
- `ProposedSolutionsController` requires the session participant to belong to the challenge and the challenge to be `open`. The solution is looked up by participant and challenge, ownership is never taken from params, and a participant can have only one proposal.
- `VotesController#update` finds the vote by participant **and** challenge, and only accepts the current round while the challenge is `voting`.

**Viewing** (`ChallengesController#show`)
- `set_participant` loads the participant from the session, scoped to this challenge.
- `set_participation_state` yields `active` or `unregistered`. Late joiners, who have no votes scheduled once voting has started, count as unregistered.
- `show.html.erb` renders `challenges/participant/<participation_state>/<challenge_status>`. The state × status matrix of partials is how the UI changes through the lifecycle. For example, `active/_voting.html.erb` shows the current round's idea and the 1–5 buttons.
- `show.csv` exports the challenge, its counts, and the ranked results with per-round scores through `lib/challenge_csv_formatter.rb`.
- An unknown challenge is a 404.

CSRF protection is on (per-form tokens). It stops other websites forging requests, but it is **not** authorisation: the layout's meta tag token works for any path, so a participant could send a valid request for any URL. Access control rests on the scoped lookups above.

## Security controls

| Control | Where | Behaviour |
|---|---|---|
| HTTPS | `config/environments/production.rb` | `force_ssl`: HTTP redirects to HTTPS (301 for GET, 308 otherwise), cookies are `Secure`. HSTS is currently **one day** with no subdomains; remove the `ssl_options` line to get Rails' default of two years once it has run cleanly |
| Session cookie | `config/initializers/session_store.rb` | Name `_twentyfiveten_session`, `HttpOnly`, `SameSite=Lax`, expires after 30 days (the data retention period) |
| Content Security Policy | `config/initializers/content_security_policy.rb` | Everything denied by default; only same-origin styles and images; no scripts. Enforced in production and test, report-only in development (Rails' error pages use inline code). If you add JavaScript or load anything from another origin, the policy must be changed |
| Permissions-Policy | `config/initializers/security_headers.rb` | Camera, microphone, geolocation, payment, USB and motion sensors off. Set directly because Rails' helper still emits the deprecated `Feature-Policy` header |
| Other headers | Rails defaults | `X-Content-Type-Options`, `Referrer-Policy`, `X-Frame-Options` |
| Rate limiting | Rails `rate_limit` in each controller | See below |
| User text | `simple_format` in views | Rendered through Rails' sanitizer, so `<script>` and event handlers are stripped. A request spec checks this |

Rate limits (a 429 beyond the limit):

| Action | Limit | Keyed by |
|---|---|---|
| Register an administrator | 10 per hour | client IP |
| Administrator login | 20 per 10 minutes | client IP |
| Join a challenge | 300 per 10 minutes | client IP (generous: a workshop may share one office IP) |
| Create or edit a proposal | 30 per 5 minutes | participant |
| Change a vote | 30 per 5 minutes | participant |

Counters live in the Rails cache, which is a per-process memory store in production, so the limits are per Puma process. Use a shared store such as Redis if the app is ever scaled to several dynos. Client IPs are read from Heroku's `X-Forwarded-For`.

## Data retention

`lib/tasks/scheduler.rake` defines `expunge_data`. The Heroku Scheduler runs it to delete Votes, ProposedSolutions, Participants and Challenges created more than 30 days ago. The UI reflects this: `Challenge#age_class` marks challenges as `old` after 20 days and `about_to_be_deleted` after 28. `spec/test/integration/expunge_data_rake_task_spec.rb` covers the task.

## Testing and CI

- `spec/requests/` covers the whole flow end to end (`challenge_flow_spec.rb`) and, per area: the lifecycle transitions, authorisation for proposals, votes and admin challenges, administrator registration and login, security headers and the session cookie, rate limits, and `force_ssl` (booted in a production-mode subprocess).
- `spec/models/` and `spec/test/integration/` cover the models, the CSV export, and the `expunge_data` task.
- Rate limiting needs a real cache, so the test environment uses a memory store, cleared before each example.
- `bin/ci` (configured in `config/ci.rb`) prepares the test database, then runs RSpec, `bundle-audit` (known gem advisories) and Brakeman (static analysis). The same command runs in GitHub Actions, so CI and local runs match.
- The workflow's third-party actions are pinned to commit SHAs, and its token is read-only (`permissions: contents: read`).
- Dependabot (`.github/dependabot.yml`) checks gems and GitHub Actions weekly, with a 7-day cooldown and one grouped PR for routine gem bumps. Security updates are not held back.
- `SECURITY.md` asks reporters to use GitHub's private vulnerability reporting.

## Layout

```
app/controllers/        Public flow, plus admin/challenges_controller.rb
app/models/             Administrator, Challenge (state machine), Participant, ProposedSolution, Vote
app/views/challenges/participant/{active,unregistered}/   Partials per participation state and challenge status
app/views/admin/challenges/                               Admin dashboard and forms
config/initializers/    Session store, CSP and other security headers
lib/challenge_csv_formatter.rb                            CSV export
lib/tasks/scheduler.rake                                  Data expunge job
vendor/assets/stylesheets/                                Vendored Skeleton and normalize.css
spec/                                                     Request, model and rake task specs
bin/ci, config/ci.rb                                      CI steps
Procfile                                                  Heroku web and release processes
docs/                                                     Screenshots referenced by README
```

## Notes and known gaps

- Authorisation rests on unguessable random IDs and cookie sessions, not accounts. Anyone holding an administrator token has full admin rights over that administrator's challenges.
- `Challenge` has no database-level foreign keys or constraints. Integrity relies on the model code.
- `schedule_votes!` assumes more than 5 participants who have submitted a proposal. With 5 or fewer, a participant may be assigned their own idea or a duplicate. This is accepted as low impact (it only affects tiny groups, and costs a little scoring accuracy), so nothing stops an administrator opening voting with too few.
- `Admin::ChallengesController` still has scaffold JSON response branches in `create` and `destroy`. The `jbuilder` gem is not installed, so there are no JSON views to render.
