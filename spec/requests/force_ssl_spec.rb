require 'open3'
require 'json'
require 'rails_helper'

# force_ssl is only configured in config/environments/production.rb, so the
# normal test environment can't see it. Boot the app in production mode in a
# subprocess (no database needed, the SSL middleware answers before the app)
# and make requests to it through Rack.
RSpec.describe "force_ssl in production" do
  SCRIPT = <<~'RUBY'.freeze
    require "json"
    request = lambda do |method, url, env = {}|
      r = Rack::MockRequest.new(Rails.application).request(method, url, env)
      { status: r.status, location: r.headers["location"], hsts: r.headers["strict-transport-security"] }
    end
    host = "http://twenty-five-ten.herokuapp.com"
    puts JSON.generate(
      http_get:  request.("GET", "#{host}/challenges/abc?x=1"),
      http_post: request.("POST", "#{host}/administrators"),
      https:     request.("GET", "https://twenty-five-ten.herokuapp.com/"),
      forwarded: request.("GET", "#{host}/", "HTTP_X_FORWARDED_PROTO" => "https")
    )
  RUBY

  before(:all) do
    out, err, status = Open3.capture3(
      { "RAILS_ENV" => "production", "SECRET_KEY_BASE_DUMMY" => "1" },
      "bin/rails", "runner", SCRIPT,
      chdir: Rails.root.to_s
    )
    raise "production boot failed:\n#{err}" unless status.success?

    @results = JSON.parse(out.lines.last, symbolize_names: true)
  end

  let(:results) { @results }

  it "redirects plain HTTP GETs to the same URL over HTTPS" do
    expect(results[:http_get][:status]).to eq(301)
    expect(results[:http_get][:location]).to eq("https://twenty-five-ten.herokuapp.com/challenges/abc?x=1")
  end

  it "redirects plain HTTP form posts too" do
    expect(results[:http_post][:status]).to eq(308)
    expect(results[:http_post][:location]).to eq("https://twenty-five-ten.herokuapp.com/administrators")
  end

  it "sends a short HSTS header over HTTPS, without includeSubDomains" do
    expect(results[:https][:hsts]).to eq("max-age=86400")
  end

  it "trusts Heroku's X-Forwarded-Proto header instead of redirecting forever" do
    expect(results[:forwarded][:status]).not_to be_between(300, 399)
    expect(results[:forwarded][:hsts]).to eq("max-age=86400")
  end
end
