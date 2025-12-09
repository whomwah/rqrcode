# frozen_string_literal: true

require_relative "benchmark_helper"

BenchmarkHelper.section "SVG Export Benchmarks"

# IPS Benchmark - SVG Export (path mode, most common use case)
BenchmarkHelper.run_ips("SVG Export") do |x, qrcodes|
  x.report("svg_small") { qrcodes[:small].as_svg(use_path: true) }
  x.report("svg_medium") { qrcodes[:medium].as_svg(use_path: true) }
  x.report("svg_large") { qrcodes[:large].as_svg(use_path: true) }

  x.compare!
end

# Memory Profile - SVG Export
BenchmarkHelper.run_memory("SVG Export") do |qrcodes|
  50.times do
    qrcodes[:small].as_svg(use_path: true)
    qrcodes[:medium].as_svg(use_path: true)
    qrcodes[:large].as_svg(use_path: true)
  end
end

puts "\n✓ SVG benchmarks complete"
