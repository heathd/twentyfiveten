require 'rails_helper'

RSpec.describe "Security headers and session cookie", type: :request do
  let(:administrator) { Administrator.create! }
  let(:challenge)     { Challenge.create!(administrator: administrator, challenge_prompt: "A") }

  describe "Content-Security-Policy" do
    it "is enforced, not report-only, and denies everything by default" do
      get root_path

      expect(response.headers["Content-Security-Policy-Report-Only"]).to be_nil
      csp = response.headers["Content-Security-Policy"]
      expect(csp).to include("default-src 'none'")
      expect(csp).to include("style-src 'self'")
      expect(csp).to include("img-src 'self'")
      expect(csp).to include("base-uri 'self'")
      expect(csp).to include("form-action 'self'")
      expect(csp).to include("frame-ancestors 'none'")
    end

    it "does not allow scripts or inline styles" do
      get root_path

      csp = response.headers["Content-Security-Policy"]
      expect(csp).not_to include("script-src")
      expect(csp).not_to include("unsafe-inline")
      expect(csp).not_to include("unsafe-eval")
    end

    it "is sent on challenge pages as well" do
      get challenge_path(challenge)

      expect(response.headers["Content-Security-Policy"]).to be_present
    end

    # The CSP above is only safe because pages carry no inline code. If this
    # fails, either remove the inline code or relax the policy deliberately.
    it "is compatible with the pages: no inline scripts, styles or event handlers" do
      get root_path
      get challenge_path(challenge)

      expect(response.body).not_to match(/<script/i)
      expect(response.body).not_to match(/<style/i)
      expect(response.body).not_to match(/\sstyle=/i)
      expect(response.body).not_to match(/\son(click|load|submit|error)=/i)
    end
  end

  describe "other response headers" do
    before { get root_path }

    it "disables browser features the app does not use" do
      policy = response.headers["Permissions-Policy"]
      %w[camera microphone geolocation payment usb].each do |feature|
        expect(policy).to include("#{feature}=()")
      end
    end

    it "does not also send the deprecated Feature-Policy header" do
      expect(response.headers["Feature-Policy"]).to be_nil
    end

    it "keeps the Rails defaults" do
      expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
      expect(response.headers["Referrer-Policy"]).to eq("strict-origin-when-cross-origin")
      expect(response.headers["X-Frame-Options"]).to eq("SAMEORIGIN")
    end
  end

  describe "session cookie" do
    # CSRF protection is off in the test environment, so a plain GET does not
    # touch the session; registering an administrator does.
    before { post administrators_path }

    let(:cookie) { response.headers["Set-Cookie"].to_s.downcase }

    it "has the same name as before, so existing sessions survive" do
      expect(cookie).to start_with("_twentyfiveten_session=")
    end

    it "is not readable by JavaScript and is not sent on cross-site requests" do
      expect(cookie).to include("httponly")
      expect(cookie).to include("samesite=lax")
    end

    it "expires after 30 days rather than lasting only until the browser closes" do
      expires = cookie[/expires=([^;]+)/, 1]
      expect(expires).to be_present

      expect(Time.parse(expires)).to be_within(1.day).of(30.days.from_now)
    end
  end
end
