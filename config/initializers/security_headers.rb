# Rails' own permissions_policy helper still emits the deprecated Feature-Policy
# header, so set the standard Permissions-Policy header directly.
#
# The app uses none of these browser features, so switch them all off.
Rails.application.config.action_dispatch.default_headers.merge!(
  "Permissions-Policy" => %w[
    accelerometer camera geolocation gyroscope microphone payment usb
  ].map { |feature| "#{feature}=()" }.join(", ")
)
