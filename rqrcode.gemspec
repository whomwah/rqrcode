lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rqrcode/version"

Gem::Specification.new do |spec|
  spec.name = "rqrcode"
  spec.version = RQRCode::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Duncan Robertson"]
  spec.email = ["duncan@whomwah.com"]

  spec.summary = "A library to encode QR Codes"
  spec.description = <<~EOF
    rqrcode is a library for encoding QR Codes. The simple
    interface allows you to create QR Code data structures
    and then render them in the way you choose.
  EOF
  spec.homepage = "https://github.com/whomwah/rqrcode"
  spec.license = "MIT"
  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/whomwah/rqrcode/issues",
    "changelog_uri" => "https://github.com/whomwah/rqrcode/blob/main/CHANGELOG.md"
  }

  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = "~> 3.0"
  spec.add_dependency "rqrcode_core", "~> 2.0"
  spec.add_dependency "chunky_png", "~> 1.0"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "standard", "~> 1.41"
end
