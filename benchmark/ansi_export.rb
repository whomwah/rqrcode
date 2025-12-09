# frozen_string_literal: true

require_relative "benchmark_helper"

BenchmarkHelper.section "ANSI Export Benchmarks"

# IPS Benchmark - ANSI Export
BenchmarkHelper.run_ips("ANSI Export") do |x, qrcodes|
  x.report("ansi_small") { qrcodes[:small].as_ansi }
  x.report("ansi_medium") { qrcodes[:medium].as_ansi }
  x.report("ansi_large") { qrcodes[:large].as_ansi }

  x.compare!
end

# Memory Profile - ANSI Export
BenchmarkHelper.run_memory("ANSI Export") do |qrcodes|
  50.times do
    qrcodes[:small].as_ansi
    qrcodes[:medium].as_ansi
    qrcodes[:large].as_ansi
  end
end

puts "\n✓ ANSI benchmarks complete"
