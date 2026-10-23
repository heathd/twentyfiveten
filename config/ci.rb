# Run using bin/ci

CI.run do
  step "Setup: test database", "env RAILS_ENV=test bin/rails db:create db:migrate"
  step "Tests: RSpec", "bundle exec rspec"
end
