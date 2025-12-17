# frozen_string_literal: true

require_relative "benchmark_helper"

BenchmarkHelper.section "PNG Export Benchmarks"

# PRIMARY: End-to-end benchmark (generation + export)
BenchmarkHelper.run_ips_e2e("PNG Export") do |x, qr_data|
  x.report("png_small") { RQRCode::QRCode.new(qr_data[:small]).as_png }
  x.report("png_medium") { RQRCode::QRCode.new(qr_data[:medium]).as_png }
  x.report("png_large") { RQRCode::QRCode.new(qr_data[:large]).as_png }

  x.compare!
end

# DIAGNOSTIC: Rendering-only benchmark (isolates export performance)
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
puts "  - End-to-end: Full user workflow (generation + export)"
puts "  - Rendering-only: Export performance in isolation"
