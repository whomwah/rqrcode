# RQRCode Benchmarks

This directory contains benchmarks for tracking RQRCode performance over time, measuring both **end-to-end workflows** (generation + export) and **rendering-only** performance.

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
- Compare before/after optimisation results
- Share baseline results with the team
- Generate summary reports comparing different runs

**Note:** The `results/` directory is gitignored - results are local to your machine.

## Benchmark Types

All benchmarks run **two modes**:

### 1. End-to-end (PRIMARY METRIC)
Measures the complete user workflow: `RQRCode::QRCode.new(data).as_svg`
- **What it shows**: Total time users experience, including rqrcode_core generation
- **Why it matters**: This is what users actually do - reflects real-world performance
- **When to use**: Track overall improvements, compare formats for actual usage
- **File naming**: `ips_e2e_*_YYYYMMDD_HHMMSS.json`

### 2. Rendering-only (DIAGNOSTIC METRIC)
Measures only export performance using pre-generated QR codes
- **What it shows**: Export format performance in isolation
- **Why it matters**: Helps identify which export method needs optimisation
- **When to use**: When optimising export code, isolating rendering bottlenecks
- **File naming**: `ips_*_YYYYMMDD_HHMMSS.json`

**Key Insight**: End-to-end benchmarks often show QR generation is the bottleneck (all formats perform similarly), while rendering-only benchmarks reveal significant differences between export formats (SVG can be 7-8x slower than ANSI).

## Available Benchmarks

Each benchmark tests 3 QR code sizes (small, medium, large) with realistic data and runs both end-to-end and rendering-only modes:

### Format Comparison (`benchmark/format_comparison.rb`)
Compares all export formats head-to-head using a medium-sized QR code.
- **End-to-end metric**: Which format is fastest for users? (Usually ~same due to generation overhead)
- **Rendering-only metric**: Which export format is most efficient?

### SVG Export (`benchmark/svg_export.rb`)
Tests SVG path mode (most common use case) across different QR sizes.
- **End-to-end metric**: Total time for generation + SVG export
- **Rendering-only metric**: SVG rendering performance in isolation

### PNG Export (`benchmark/png_export.rb`)
Tests PNG with default sizing (most common use case) across different QR sizes.
- **End-to-end metric**: Total time for generation + PNG export
- **Rendering-only metric**: PNG rendering performance in isolation

### HTML Export (`benchmark/html_export.rb`)
Tests HTML table export across different QR sizes.
- **End-to-end metric**: Total time for generation + HTML export
- **Rendering-only metric**: HTML rendering performance in isolation

### ANSI Export (`benchmark/ansi_export.rb`)
Tests ANSI terminal output across different QR sizes.
- **End-to-end metric**: Total time for generation + ANSI export
- **Rendering-only metric**: ANSI rendering performance in isolation

## Understanding the JSON Output

### End-to-end Results
Files named `ips_e2e_*` contain generation + export times:
```json
{
  "label": "All Export Formats (end-to-end)",
  "timestamp": "2025-12-17T21:46:51+00:00",
  "ruby_version": "3.3.4",
  "results": {
    "svg": {
      "iterations_per_second": 16.71,
      "standard_deviation": 0.00,
      "samples": 84,
      "comparison": 1.09
    },
    "ansi": {
      "iterations_per_second": 18.13,
      "standard_deviation": 5.50,
      "samples": 91,
      "comparison": 1.0
    }
  }
}
```

### Rendering-only Results
Files named `ips_*` (without `e2e`) contain export-only times:
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

**Common fields:**
- `iterations_per_second`: Higher is better (more iterations completed per second)
- `standard_deviation`: Lower is more consistent (percent variation)
- `comparison`: Multiplier vs fastest (1.0x = fastest, higher = slower)
- `samples`: Number of iterations run for measurement

## Test Data

Benchmarks use 3 representative QR code sizes:
- **small**: GitHub URL (~40 chars, typical use case)
- **medium**: Lorem ipsum sentence (~100 chars)
- **large**: 500 characters (stress test)

## Interpreting Results

### What to track over time:
1. **End-to-end i/s**: Are users getting faster overall? (Includes rqrcode_core improvements)
2. **Rendering-only i/s**: Are export methods getting more efficient?
3. **Relative comparisons**: How do formats compare to each other in both modes?
4. **Memory allocations**: Are we creating fewer objects?

### Interpreting Performance Changes

**When end-to-end improves but rendering-only doesn't:**
- Improvements came from rqrcode_core (QR generation algorithm)
- Export methods haven't changed

**When rendering-only improves but end-to-end shows modest gains:**
- Export methods got faster, but generation time dominates
- For small improvements, generation overhead masks rendering gains

**When both improve proportionally:**
- Changes benefited the whole pipeline

## Latest Benchmark Results

**Last Updated: 2025-12-17 21:59:00 UTC**
**Ruby Version: 3.3.4**
**Platform: Apple M-series**
**rqrcode_core version: 2.0.1 (feat/performance101 branch with 80-90% generation improvements)**

### Quick Reference Baselines

#### End-to-end (Generation + Export) - Medium QR Code
*User-facing performance - what matters for real-world usage*

| Format | Iterations/sec | Std Dev | Samples | Slowdown vs Fastest | vs Previous |
|--------|----------------|---------|---------|---------------------|-------------|
| ANSI   | 33.0          | 0.00%   | 165     | 1.00x (baseline)   | +82% 🚀    |
| PNG    | 32.5          | 0.00%   | 165     | 1.01x (same-ish)   | +80% 🚀    |
| HTML   | 32.2          | 0.00%   | 162     | 1.02x (same-ish)   | +79% 🚀    |
| SVG    | 28.3          | 0.00%   | 142     | 1.17x              | +69% 🚀    |

**Key Insight**: All formats perform similarly (~28-33 i/s) because QR generation dominates the time. The 69-82% improvement across all formats reflects the rqrcode_core optimisation. Format choice has minimal impact on end-to-end performance.

#### Rendering-only (Export Performance) - Medium QR Code
*Diagnostic metric - shows export efficiency in isolation*

| Format | Iterations/sec | Std Dev | Samples | Slowdown vs Fastest | vs Previous |
|--------|----------------|---------|---------|---------------------|-------------|
| ANSI   | 1,315         | 0.50%   | 6,603   | 1.00x (baseline)   | ✅ stable   |
| PNG    | 823           | 3.40%   | 4,150   | 1.60x              | ✅ stable   |
| HTML   | 616           | 1.30%   | 3,087   | 2.14x              | ✅ stable   |
| SVG    | 171           | 4.10%   | 867     | 7.67x              | ✅ stable   |

**Key Insight**: Export format differences are dramatic when isolated. SVG rendering is 7.7x slower than ANSI, indicating optimisation opportunities. Rendering-only performance remained stable (as expected) while end-to-end improved dramatically.

### Performance by QR Code Size
*Note: Higher iterations/sec is better; lower std dev is better; lower slowdown is better*

#### SVG Export (End-to-end)
| Size   | Iterations/sec | Std Dev | Slowdown vs Small | vs Previous |
|--------|----------------|---------|-------------------|-------------|
| Small  | 90.2          | 0.00%   | 1.00x (baseline) | +71% 🚀    |
| Medium | 28.6          | 0.00%   | 3.16x            | +69% 🚀    |
| Large  | 9.3           | 0.00%   | 9.65x            | +79% 🚀    |

#### PNG Export (End-to-end)
| Size   | Iterations/sec | Std Dev | Slowdown vs Small | vs Previous |
|--------|----------------|---------|-------------------|-------------|
| Small  | 98.3          | 0.00%   | 1.00x (baseline) | +72% 🚀    |
| Medium | 32.1          | 0.00%   | 3.07x            | +80% 🚀    |
| Large  | 11.0          | 0.00%   | 8.95x            | +79% 🚀    |

#### HTML Export (End-to-end)
| Size   | Iterations/sec | Std Dev | Slowdown vs Small | vs Previous |
|--------|----------------|---------|-------------------|-------------|
| Small  | 102.0         | 0.00%   | 1.00x (baseline) | +77% 🚀    |
| Medium | 31.8          | 0.00%   | 3.21x            | +79% 🚀    |
| Large  | 10.8          | 0.00%   | 9.42x            | +80% 🚀    |

#### ANSI Export (End-to-end)
| Size   | Iterations/sec | Std Dev | Slowdown vs Small | vs Previous |
|--------|----------------|---------|-------------------|-------------|
| Small  | 105.6         | 0.00%   | 1.00x (baseline) | +87% 🚀    |
| Medium | 32.9          | 0.00%   | 3.21x            | +82% 🚀    |
| Large  | 11.2          | 0.00%   | 9.43x            | +80% 🚀    |

### Memory Allocations
*Note: Lower is better for both metrics*

| Format | Total Objects Allocated | Total Memory (MB) |
|--------|-------------------------|-------------------|
| ANSI   | 40,701                 | 16.2              |
| PNG    | 357,676                | 22.0              |
| HTML   | 1,441,201              | 155.8             |
| SVG    | 7,443,651              | 374.4             |

**Key Insights:**
- **Major improvement**: rqrcode_core optimisations delivered 69-87% faster end-to-end performance across all formats! 🎉
- **End-to-end**: QR generation is the bottleneck - format choice barely matters (~28-33 i/s for all)
- **Rendering-only**: ANSI is fastest (1,315 i/s), SVG is slowest (171 i/s) and most memory-intensive
- **Validation**: Rendering-only benchmarks remained stable, confirming improvements came from rqrcode_core
- **Optimisation priority**: Improvements to rqrcode_core have biggest impact on user experience (proven!)
- **Format choice**: For high-volume rendering, ANSI/PNG are significantly faster than SVG/HTML
- All formats show 3-10x performance degradation as QR size increases
- Memory usage varies dramatically: ANSI uses 23x less memory than SVG

## Notes

- **Primary metric**: End-to-end results reflect real user experience
- **Secondary metric**: Rendering-only helps diagnose where to optimise
- Focus on relative comparisons, not absolute numbers
- Results vary by system (CPU, Ruby version, rqrcode_core version)
- Run benchmarks before and after making changes to measure impact
- Full suite runs in ~2-3 minutes (doubled due to two modes per benchmark)
- When rqrcode_core updates, expect end-to-end improvements even without changes to this gem
