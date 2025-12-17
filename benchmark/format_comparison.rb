# frozen_string_literal: true

require_relative "benchmark_helper"

BenchmarkHelper.section "Format Comparison Benchmarks"

# PRIMARY: End-to-end benchmark (generation + export) - what users actually do
BenchmarkHelper.run_ips_e2e("All Export Formats") do |x, qr_data|
  data = qr_data[:medium]

  x.report("svg") { RQRCode::QRCode.new(data).as_svg(use_path: true) }
  x.report("png") { RQRCode::QRCode.new(data).as_png }
  x.report("html") { RQRCode::QRCode.new(data).as_html }
  x.report("ansi") { RQRCode::QRCode.new(data).as_ansi }

  x.compare!
end

# DIAGNOSTIC: Rendering-only benchmark (isolates export performance)
BenchmarkHelper.run_ips("All Export Formats") do |x, qrcodes|
  qr = qrcodes[:medium]

  x.report("svg") { qr.as_svg(use_path: true) }
  x.report("png") { qr.as_png }
  x.report("html") { qr.as_html }
  x.report("ansi") { qr.as_ansi }

  x.compare!
end

puts "\n✓ Format comparison benchmarks complete"
puts "  - End-to-end: Full user workflow (generation + export)"
puts "  - Rendering-only: Export performance in isolation"
