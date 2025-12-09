# frozen_string_literal: true

require_relative "benchmark_helper"

BenchmarkHelper.section "Format Comparison Benchmarks"

# IPS Benchmark - Compare all export formats (medium QR code)
BenchmarkHelper.run_ips("All Export Formats") do |x, qrcodes|
  qr = qrcodes[:medium]

  x.report("svg") { qr.as_svg(use_path: true) }
  x.report("png") { qr.as_png }
  x.report("html") { qr.as_html }
  x.report("ansi") { qr.as_ansi }

  x.compare!
end

puts "\n✓ Format comparison benchmarks complete"
