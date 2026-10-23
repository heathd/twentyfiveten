# Run using bin/ci

CI.run do
  step "Setup: test database", "env RAILS_ENV=test bin/rails db:create db:migrate"
  step "Build: CSS", "bin/rails dartsass:build"
  step "Tests: RSpec", "bundle exec rspec"
  # The production asset build is stricter than the test environment and has failed on its own
  # before, so check it too. It writes to public/assets, which is removed again afterwards.
  step "Build: production assets", "env RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 sh -c 'bin/rails assets:precompile; status=$?; bin/rails assets:clobber; exit $status'"
  step "Security: gem advisories", "bundle exec bundle-audit check --update"
  step "Security: static analysis", "bundle exec brakeman -q --no-pager -A"
end
