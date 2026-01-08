# frozen_string_literal: true

require_relative "benchmark_helper"

BenchmarkHelper.section "ANSI Export Benchmarks"

# PRIMARY: End-to-end benchmark (generation + export)
BenchmarkHelper.run_ips_e2e("ANSI Export") do |x, qr_data|
  x.report("ansi_small") { RQRCode::QRCode.new(qr_data[:small]).as_ansi }
  x.report("ansi_medium") { RQRCode::QRCode.new(qr_data[:medium]).as_ansi }
  x.report("ansi_large") { RQRCode::QRCode.new(qr_data[:large]).as_ansi }

  x.compare!
end

# DIAGNOSTIC: Rendering-only benchmark (isolates export performance)
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
puts "  - End-to-end: Full user workflow (generation + export)"
puts "  - Rendering-only: Export performance in isolation"
