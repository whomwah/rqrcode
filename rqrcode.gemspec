# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rqrcode/version"

Gem::Specification.new do |s|
  s.name        = "rqrcode"
  s.version     = RQRCode::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Duncan Robertson"]
  s.email       = ["duncan@whomwah.com"]
  s.homepage    = "http://whomwah.github.com/rqrcode/"
  s.summary     = "A library to encode QR Codes" 
  s.description = <<EOF
rQRCode is a library for encoding QR Codes. The simple
interface allows you to create QR Code data structures 
ready to be displayed in the way you choose. 
EOF
  
  s.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')

  s.add_development_dependency "rake"
  s.add_development_dependency("bundler", ">= 1.0.0")

  s.has_rdoc      = true
  s.extra_rdoc_files = ["README.md", "CHANGELOG", "LICENSE"]  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
