require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

NAME = "rqrcode"
VERS = "0.1.0"
CLEAN.include ['pkg']

Gem::manage_gems

spec = Gem::Specification.new do |s|
  s.name      = NAME
  s.version   = VERS
  s.author    = "Duncan Robertson"
  s.email     = "duncan@whomwah.com"
  s.homepage  = "http://whomwah.com"
  s.platform  = Gem::Platform::RUBY
  s.summary   = "A lib to generation QRCodes" 
  s.description   = s.summary
  s.files = FileList["{test,lib}/**/*"].exclude("rdoc").to_a
  s.require_path  = "lib"
  s.autorequire   = "rqrcode"
  s.test_files = Dir.glob('test/*_test.rb')
  s.extra_rdoc_files = ["README","CHANGELOG"]  
  s.add_dependency("rake")
end

task :build_package => [:repackage]
Rake::GemPackageTask.new(spec) do |pkg|
  #pkg.need_zip = true
  #pkg.need_tar = true
  pkg.gem_spec = spec
end

desc "Default: run unit tests."
task :default => :test

desc "Run all the tests"
Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.pattern = "test/**/*_test.rb"
  t.verbose = true
end
