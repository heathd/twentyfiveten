# Run using bin/ci

CI.run do
  step "Setup: test database", "env RAILS_ENV=test bin/rails db:create db:migrate"
  step "Tests: RSpec", "bundle exec rspec"
  step "Security: gem advisories", "bundle exec bundle-audit check --update"
  step "Security: static analysis", "bundle exec brakeman -q --no-pager -A"
end
