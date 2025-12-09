# frozen_string_literal: true

require "bundler/setup"
require "rqrcode"
require "benchmark/ips"
require "memory_profiler"
require "stackprof"
require "json"
require "fileutils"
require "time"

module BenchmarkHelper
  # Test data of varying sizes
  QR_DATA = {
    tiny: "Hi",
    small: "https://github.com/whomwah/rqrcode",
    medium: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore.",
    large: "A" * 500,
    xlarge: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 20
  }.freeze

  # Create QR codes for benchmarking
  def self.qrcodes
    @qrcodes ||= QR_DATA.transform_values { |data| RQRCode::QRCode.new(data) }
  end

  # Get results directory
  def self.results_dir
    @results_dir ||= File.join(__dir__, "results")
  end

  # Ensure results directory exists
  def self.ensure_results_dir
    FileUtils.mkdir_p(results_dir) unless Dir.exist?(results_dir)
  end

  # Get timestamp for filename
  def self.timestamp
    @timestamp ||= Time.now.strftime("%Y%m%d_%H%M%S")
  end

  # Save results to JSON
  def self.save_results(name, data)
    ensure_results_dir
    filename = File.join(results_dir, "#{name}_#{timestamp}.json")
    File.write(filename, JSON.pretty_generate(data))
    puts "\n💾 Results saved to: #{filename}"
  end

  # Run IPS benchmark
  def self.run_ips(label, warmup: 2, time: 5, &block)
    puts "\n" + "=" * 80
    puts "IPS Benchmark: #{label}"
    puts "=" * 80

    results = {}
    report = Benchmark.ips do |x|
      x.config(warmup: warmup, time: time)
      block.call(x, qrcodes)
      x.compare!
    end

    # Extract actual metrics from the report
    report.entries.each do |entry|
      results[entry.label] = {
        iterations_per_second: entry.stats.central_tendency.round(2),
        standard_deviation: entry.stats.error_percentage.round(2),
        samples: entry.measurement_cycle
      }
    end

    # Calculate comparison ratios (fastest = 1.0x)
    if results.any?
      fastest_ips = results.values.map { |r| r[:iterations_per_second] }.max
      results.each do |_label, data|
        data[:comparison] = (fastest_ips / data[:iterations_per_second]).round(2)
      end
    end

    # Save results with actual metrics
    save_results(
      "ips_#{label.downcase.gsub(/\s+/, "_")}",
      {
        label: label,
        timestamp: Time.now.iso8601,
        ruby_version: RUBY_VERSION,
        results: results
      }
    )

    report
  end

  # Run memory profiler
  def self.run_memory(label, &block)
    puts "\n" + "=" * 80
    puts "Memory Profile: #{label}"
    puts "=" * 80

    report = MemoryProfiler.report do
      block.call(qrcodes)
    end

    report.pretty_print(scale_bytes: true, normalize_paths: true)

    # Save memory results
    memory_data = {
      label: label,
      timestamp: Time.now.iso8601,
      ruby_version: RUBY_VERSION,
      total_allocated_memsize: report.total_allocated_memsize,
      total_retained_memsize: report.total_retained_memsize,
      total_allocated: report.total_allocated,
      total_retained: report.total_retained
    }

    save_results("memory_#{label.downcase.gsub(/\s+/, "_")}", memory_data)

    report
  end

  # Run stack profiler
  def self.run_stackprof(label, mode: :cpu, &block)
    puts "\n" + "=" * 80
    puts "Stack Profile: #{label} (#{mode} mode)"
    puts "=" * 80

    profile = StackProf.run(mode: mode, interval: 1000) do
      block.call(qrcodes)
    end

    StackProf::Report.new(profile).print_text(limit: 20)

    # Save stackprof results
    stackprof_data = {
      label: label,
      timestamp: Time.now.iso8601,
      ruby_version: RUBY_VERSION,
      mode: mode,
      samples: profile[:samples],
      frames: profile[:frames].map do |_frame_id, frame_data|
        {
          name: frame_data[:name],
          total_samples: frame_data[:samples],
          file: frame_data[:file],
          line: frame_data[:line]
        }
      end.sort_by { |f| -f[:total_samples] }.first(20)
    }

    save_results("stackprof_#{label.downcase.gsub(/\s+/, "_")}", stackprof_data)

    profile
  end

  # Convenience method to run all profiling types
  def self.profile_all(label, &block)
    run_ips(label, &block)
    run_memory(label, &block)
    run_stackprof(label, &block)
  end

  # Helper to print section header
  def self.section(title)
    puts "\n\n"
    puts "#" * 80
    puts "# #{title}"
    puts "#" * 80
    puts "Timestamp: #{timestamp}"
    puts "Ruby Version: #{RUBY_VERSION}"
  end

  # Helper to format bytes
  def self.format_bytes(bytes)
    if bytes < 1024
      "#{bytes} B"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(2)} KB"
    else
      "#{(bytes / (1024.0 * 1024)).round(2)} MB"
    end
  end
end
