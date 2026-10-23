# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header
#
# The pages serve no JavaScript, no inline styles and nothing from other
# origins: just HTML plus one same-origin stylesheet. So everything is denied
# by default and only same-origin styles and images (the favicon) are allowed.
#
# If you add JavaScript or load anything from another origin, you must allow it
# here, or the browser will block it.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :none
    policy.style_src       :self
    policy.img_src         :self
    policy.base_uri        :self
    policy.form_action     :self
    policy.frame_ancestors :none
  end

  # The Rails development error pages and web console use inline scripts and
  # styles, so only report violations in development rather than enforcing.
  config.content_security_policy_report_only = Rails.env.development?
end
