require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

NAME = "rqrcode"
VERS = "0.2.0"
CLEAN.include ['pkg', 'rdoc']

Gem::manage_gems

spec = Gem::Specification.new do |s|
  s.name						= NAME
  s.version					= VERS
  s.author					= "Duncan Robertson"
  s.email						= "duncan@whomwah.com"
  s.homepage				= "http://rqrcode.rubyforge.org"
  s.platform				= Gem::Platform::RUBY
  s.summary					= "A library to encode QR Codes" 
	s.rubyforge_project = NAME 
	s.description = <<EOF
rQRCode is a library for encoding QRCodes. The simple
interace allows you to simply create QRCodes ready to
be displayed in the way you choose. 
EOF
  s.files = FileList["lib/**/*", "test/*"].exclude("rdoc").to_a
  s.require_path		= "lib"
	s.has_rdoc				= true
  s.extra_rdoc_files = ["README", "CHANGELOG", "COPYING"]  
	s.test_file       = "test/runtest.rb"
end

task :build_package => [:repackage]
Rake::GemPackageTask.new(spec) do |pkg|
  #pkg.need_zip = true
  pkg.need_tar = true
  pkg.gem_spec = spec
end

desc "Default: run unit tests."
task :default => :test

desc "Run all the tests"
Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.pattern = "test/runtest.rb"
  t.verbose = true
end

Rake::RDocTask.new do |rd|
		rd.rdoc_dir = "rdoc"
    rd.main = "README"
    rd.rdoc_files.include("README", "CHANGELOG", "COPYING", "lib/**/*.rb")
end

desc "rdoc to rubyforge"
task :rubyforge => [:rdoc] do
	sh %{/usr/bin/scp -r -p rdoc/* rubyforge:/var/www/gforge-projects/rqrcode}
end
