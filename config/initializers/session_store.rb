# Same cookie name as before, so existing sessions keep working.
#
# expire_after matches the 30 day data retention (see the expunge_data task):
# participants and administrators stay recognised across browser restarts for
# as long as their challenge can exist, and no longer.
#
# The Secure flag is added automatically when config.force_ssl is enabled.
Rails.application.config.session_store :cookie_store,
  key: "_twentyfiveten_session",
  httponly: true,
  same_site: :lax,
  expire_after: 30.days
