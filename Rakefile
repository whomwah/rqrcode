require 'rake/testtask'
require 'bundler'

Bundler::GemHelper.install_tasks

desc "Run tests"
Rake::TestTask.new do |t|
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
end

task :default => [:test]
