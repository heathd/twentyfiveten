# Vendored assets

This file sits above `stylesheets/` on purpose: the asset pipeline publishes everything inside
`vendor/assets/stylesheets/`, and this note shouldn't be served.

## stylesheets/pico.css

[Pico CSS](https://picocss.com) v2.1.1, MIT licensed, used unmodified.

- Source: `css/pico.min.css` at tag `v2.1.1` of <https://github.com/picocss/pico>
- Cross-checked against the `@picocss/pico@2.1.1` package on npm: byte-for-byte identical
- sha256: `fbc9a63fc9fc9f72d12fd7fc9806e11fa9f77ae4f9cad146b27003a1119ba3db`
- Upstream archived the repository in October 2026; v2.1.1 (March 2025) is the final release
- It is plain CSS: Propshaft serves it as is, and it is linked separately from the app's own
  stylesheet (`pico`, then `application`, in `app/views/layouts/application.html.erb`)

Dependabot does not track this file. To update or replace it, repeat the two-source check above
and update this note.

Things this file requires elsewhere in the app:

- It draws checkmarks, select arrows and spinners as inline SVG `data:` URIs, so the
  Content-Security-Policy `img-src` must include `data:` (see
  `config/initializers/content_security_policy.rb`).
- It uses modern CSS (`:where()`, `:has()`, empty custom properties). The old SassC/Sprockets
  pipeline could not handle it; the app now uses Propshaft and Dart Sass (`dartsass-rails`) instead.
