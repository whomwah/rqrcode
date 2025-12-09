# frozen_string_literal: true

require_relative "benchmark_helper"

BenchmarkHelper.section "HTML Export Benchmarks"

# IPS Benchmark - HTML Export
BenchmarkHelper.run_ips("HTML Export") do |x, qrcodes|
  x.report("html_small") { qrcodes[:small].as_html }
  x.report("html_medium") { qrcodes[:medium].as_html }
  x.report("html_large") { qrcodes[:large].as_html }

  x.compare!
end

# Memory Profile - HTML Export
BenchmarkHelper.run_memory("HTML Export") do |qrcodes|
  50.times do
    qrcodes[:small].as_html
    qrcodes[:medium].as_html
    qrcodes[:large].as_html
  end
end

puts "\n✓ HTML benchmarks complete"
