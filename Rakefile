begin
  require "standard/rake"
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:spec)

  task default: [:spec, "standard:fix"]
rescue LoadError
  # no standard/rspec available
end
