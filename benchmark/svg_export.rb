# frozen_string_literal: true

require_relative "benchmark_helper"

BenchmarkHelper.section "SVG Export Benchmarks"

# PRIMARY: End-to-end benchmark (generation + export)
BenchmarkHelper.run_ips_e2e("SVG Export") do |x, qr_data|
  x.report("svg_small") { RQRCode::QRCode.new(qr_data[:small]).as_svg(use_path: true) }
  x.report("svg_medium") { RQRCode::QRCode.new(qr_data[:medium]).as_svg(use_path: true) }
  x.report("svg_large") { RQRCode::QRCode.new(qr_data[:large]).as_svg(use_path: true) }

  x.compare!
end

# DIAGNOSTIC: Rendering-only benchmark (isolates export performance)
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
puts "  - End-to-end: Full user workflow (generation + export)"
puts "  - Rendering-only: Export performance in isolation"
