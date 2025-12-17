# frozen_string_literal: true

require_relative "benchmark_helper"

BenchmarkHelper.section "HTML Export Benchmarks"

# PRIMARY: End-to-end benchmark (generation + export)
BenchmarkHelper.run_ips_e2e("HTML Export") do |x, qr_data|
  x.report("html_small") { RQRCode::QRCode.new(qr_data[:small]).as_html }
  x.report("html_medium") { RQRCode::QRCode.new(qr_data[:medium]).as_html }
  x.report("html_large") { RQRCode::QRCode.new(qr_data[:large]).as_html }

  x.compare!
end

# DIAGNOSTIC: Rendering-only benchmark (isolates export performance)
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
puts "  - End-to-end: Full user workflow (generation + export)"
puts "  - Rendering-only: Export performance in isolation"
