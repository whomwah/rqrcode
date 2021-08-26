# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2021-08-26

- Sync Gemfile.lock with `rqrcode_core.1.2.0` [Adds Multimode Support](https://github.com/whomwah/rqrcode_core#multiple-encoding-support)
- Add badge for Standard linting

### Changed

- Corrected method name referred to in CHANGELOG.

## [2.0.0] - 2021-05-06

### Added

- A new `use_path:` option on `.as_svg`. This uses a `<path>` node to greatly reduce the final SVG size. [#108]
- A new `viewbox:` option on `.as_svg`. Replaces the `svg.width` and `svg.height` attribute with `svg.viewBox` to allow CSS scaling. [#112]
- A new `svg_attributes:` option on `.as_svg`. Allows you to pass in custom SVG attributes to be used in the `<svg>` tag. [#113]

### Changed

- README updated
- Rakefile cleaned up. You can now just run `rake` which will run specs and fix linting using `standardrb`
- Small documentation clarification [@smnscp](https://github.com/smnscp)
- Bump `rqrcode_core` to `~> 1.0`

### Breaking Change

- The dependency `rqrcode_core-1.0.0` has a tiny breaking change to the `to_s` public method. https://github.com/whomwah/rqrcode_core/blob/master/CHANGELOG.md#breaking-changes

## [1.2.0] - 2020-12-26

### Changed

- README updated
- bump dependencies
- fix `required_ruby_version` for Ruby 3 support

[unreleased]: https://github.com/whomwah/rqrcode/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/whomwah/rqrcode/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/whomwah/rqrcode/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/whomwah/rqrcode/compare/v1.1.1...v1.2.0
