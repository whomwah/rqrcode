# RQRCode Benchmarks

This directory contains streamlined benchmarks for tracking RQRCode export performance over time.

## Quick Start

```bash
# Install dependencies
bundle install

# Run specific format benchmarks
rake benchmark:svg
rake benchmark:png
rake benchmark:html
rake benchmark:ansi
rake benchmark:format_comparison

# Run all benchmarks (takes ~1-2 minutes)
rake benchmark:all
```

## Results Storage

**All benchmark results are automatically saved to `benchmark/results/` as JSON files.**

Each run creates timestamped files with the format:
- `ips_<benchmark_name>_YYYYMMDD_HHMMSS.json` - Performance data (iterations/sec, comparisons)
- `memory_<benchmark_name>_YYYYMMDD_HHMMSS.json` - Memory allocation data

This allows you to:
- Track performance changes over time
- Compare before/after optimization results
- Share baseline results with the team
- Generate summary reports comparing different runs

**Note:** The `results/` directory is gitignored - results are local to your machine.

## Available Benchmarks

Each benchmark tests 3 QR code sizes (small, medium, large) with realistic data:

### Format Comparison (`benchmark/format_comparison.rb`)
Compares all export formats head-to-head using a medium-sized QR code.
- **Key metric**: Which format is fastest overall?

### SVG Export (`benchmark/svg_export.rb`)
Tests SVG path mode (most common use case).
- **Key metric**: Performance across different QR sizes

### PNG Export (`benchmark/png_export.rb`)
Tests PNG with default sizing (most common use case).
- **Key metric**: Performance across different QR sizes

### HTML Export (`benchmark/html_export.rb`)
Tests HTML table export.
- **Key metric**: Performance across different QR sizes

### ANSI Export (`benchmark/ansi_export.rb`)
Tests ANSI terminal output.
- **Key metric**: Performance across different QR sizes

## Understanding the JSON Output

Example IPS result:
```json
{
  "label": "All Export Formats",
  "timestamp": "2025-12-09T19:49:35+00:00",
  "ruby_version": "3.3.4",
  "results": {
    "svg": {
      "iterations_per_second": 186.71,
      "standard_deviation": 0.54,
      "samples": 18,
      "comparison": 7.28
    },
    "ansi": {
      "iterations_per_second": 1359.48,
      "standard_deviation": 0.22,
      "samples": 135,
      "comparison": 1.0
    }
  }
}
```

- `iterations_per_second`: Higher is better
- `standard_deviation`: Lower is more consistent
- `comparison`: Multiplier vs fastest (1.0x = fastest)

## Test Data

Benchmarks use 3 representative QR code sizes:
- **small**: GitHub URL (~40 chars, typical use case)
- **medium**: Lorem ipsum sentence (~100 chars)
- **large**: 500 characters (stress test)

## Interpreting Results

### What to track over time:
1. **Iterations per second**: Is performance improving or degrading?
2. **Relative comparisons**: How do formats compare to each other?
3. **Memory allocations**: Are we creating fewer objects?

### Current Performance Baselines (Apple M-series, Ruby 3.3.4)
For medium-sized QR codes:
- ANSI: ~1350 i/s (fastest)
- PNG: ~860 i/s
- HTML: ~650 i/s
- SVG: ~190 i/s

## Latest Benchmark Results

**Last Updated: 2025-12-09 20:00:37 UTC**
**Ruby Version: 3.3.4**

### Format Comparison (Medium QR Code)

| Format | Iterations/sec | Std Dev | Samples | Slowdown vs Fastest |
|--------|----------------|---------|---------|---------------------|
| ANSI   | 1,367.46      | 0.51%   | 136     | 1.00x (baseline)   |
| PNG    | 865.86        | 0.92%   | 87      | 1.58x              |
| HTML   | 653.38        | 0.31%   | 65      | 2.09x              |
| SVG    | 183.67        | 1.09%   | 18      | 7.45x              |

### Performance by QR Code Size

#### SVG Export
| Size   | Iterations/sec | Std Dev | Slowdown vs Small |
|--------|----------------|---------|-------------------|
| Small  | 547.83        | 0.37%   | 1.00x (baseline) |
| Medium | 188.04        | 0.53%   | 2.91x            |
| Large  | 47.47         | 4.21%   | 11.54x           |

#### PNG Export
| Size   | Iterations/sec | Std Dev | Slowdown vs Small |
|--------|----------------|---------|-------------------|
| Small  | 1,183.86      | 0.59%   | 1.00x (baseline) |
| Medium | 857.01        | 1.75%   | 1.38x            |
| Large  | 303.14        | 0.66%   | 3.91x            |

#### HTML Export
| Size   | Iterations/sec | Std Dev | Slowdown vs Small |
|--------|----------------|---------|-------------------|
| Small  | 1,914.90      | 1.04%   | 1.00x (baseline) |
| Medium | 659.26        | 0.30%   | 2.90x            |
| Large  | 228.95        | 1.75%   | 8.36x            |

#### ANSI Export
| Size   | Iterations/sec | Std Dev | Slowdown vs Small |
|--------|----------------|---------|-------------------|
| Small  | 3,954.51      | 1.06%   | 1.00x (baseline) |
| Medium | 1,359.47      | 1.47%   | 2.91x            |
| Large  | 478.66        | 1.88%   | 8.26x            |

### Memory Allocations

| Format | Total Objects Allocated | Total Memory (MB) |
|--------|-------------------------|-------------------|
| ANSI   | 40,701                 | 16.2              |
| PNG    | 357,676                | 23.1              |
| HTML   | 1,441,201              | 163.3             |
| SVG    | 7,432,001              | 375.7             |

**Key Insights:**
- ANSI is the fastest format (1,367 i/s) and most memory-efficient (40.7k objects)
- SVG is the slowest format (183 i/s) and most memory-intensive (7.4M objects)
- All formats show 3-12x performance degradation as QR size increases
- Memory usage varies dramatically: ANSI uses 23x less memory than SVG

## Notes

- Focus on relative comparisons, not absolute numbers
- Results vary by system (CPU, Ruby version)
- Run benchmarks before and after making changes
- Full suite runs in ~1-2 minutes
