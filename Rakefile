begin
  require "standard/rake"
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:spec)

  task default: [:spec, "standard:fix"]
rescue LoadError
  # no standard/rspec available
end

# Benchmark tasks
namespace :benchmark do
  desc "Run all benchmarks"
  task :all do
    %w[svg png html ansi format_comparison].each do |format|
      Rake::Task["benchmark:#{format}"].invoke
    end
  end

  desc "Run SVG export benchmarks"
  task :svg do
    ruby "benchmark/svg_export.rb"
  end

  desc "Run PNG export benchmarks"
  task :png do
    ruby "benchmark/png_export.rb"
  end

  desc "Run HTML export benchmarks"
  task :html do
    ruby "benchmark/html_export.rb"
  end

  desc "Run ANSI export benchmarks"
  task :ansi do
    ruby "benchmark/ansi_export.rb"
  end

  desc "Run format comparison benchmarks"
  task :format_comparison do
    ruby "benchmark/format_comparison.rb"
  end
end
