# frozen_string_literal: true

require_relative "benchmark_helper"

BenchmarkHelper.section "PNG Export Benchmarks"

# IPS Benchmark - PNG Export (default sizing, most common use case)
BenchmarkHelper.run_ips("PNG Export") do |x, qrcodes|
  x.report("png_small") { qrcodes[:small].as_png }
  x.report("png_medium") { qrcodes[:medium].as_png }
  x.report("png_large") { qrcodes[:large].as_png }

  x.compare!
end

# Memory Profile - PNG Export
BenchmarkHelper.run_memory("PNG Export") do |qrcodes|
  25.times do
    qrcodes[:small].as_png
    qrcodes[:medium].as_png
    qrcodes[:large].as_png
  end
end

puts "\n✓ PNG benchmarks complete"
