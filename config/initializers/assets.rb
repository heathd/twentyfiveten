# Propshaft publishes everything on its asset paths. Keep only what this app serves:
# the CSS built from the SCSS (app/assets/builds), Pico (vendor/assets/stylesheets) and images.
#
# Dropped from the paths:
#  * app/assets/stylesheets: the SCSS sources, which dartsass-rails compiles into app/assets/builds
#  * the JavaScript and CSS that Rails' frameworks bring along (Action Cable, Action Text, Trix,
#    Active Storage, rails-ujs), none of which this app uses
Rails.application.config.after_initialize do |app|
  scss_sources = Rails.root.join("app/assets/stylesheets").to_s

  app.config.assets.paths.select! do |path|
    path.to_s.start_with?(Rails.root.to_s) && path.to_s != scss_sources
  end
end
