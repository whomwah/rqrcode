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

**Key Insight**: End-to-end benchmarks often show QR generation is the bottleneck (all formats perform similarly), while rendering-only benchmarks reveal differences between export formats (SVG is ~4x slower than HTML due to algorithmic complexity).

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

**Last Updated: 2026-01-08 14:09:06 UTC**
**Ruby Version: 3.3.4**
**Platform: Apple M-series**
**rqrcode_core version: 2.0.1**

### Quick Reference Baselines

#### End-to-end (Generation + Export) - Medium QR Code
*User-facing performance - what matters for real-world usage*

| Format | Iterations/sec | Std Dev | Samples | Slowdown vs Fastest |
|--------|----------------|---------|---------|---------------------|
| HTML   | 34.1          | 2.90%   | 171     | 1.00x (baseline)   |
| ANSI   | 34.1          | 0.00%   | 171     | 1.00x (same-ish)   |
| PNG    | 33.6          | 0.00%   | 171     | 1.01x (same-ish)   |
| SVG    | 32.2          | 0.00%   | 162     | 1.06x (same-ish)   |

**Key Insight**: All formats now perform very similarly (~32-34 i/s) because QR generation dominates the time. SVG optimisations brought it in line with other formats for end-to-end usage.

#### Rendering-only (Export Performance) - Medium QR Code
*Diagnostic metric - shows export efficiency in isolation*

| Format | Iterations/sec | Std Dev | Samples | Slowdown vs Fastest |
|--------|----------------|---------|---------|---------------------|
| HTML   | 1,876         | 0.70%   | 9,464   | 1.00x (baseline)   |
| ANSI   | 1,310         | 6.20%   | 6,615   | 1.43x              |
| PNG    | 840           | 4.90%   | 4,214   | 2.23x              |
| SVG    | 424           | 1.70%   | 2,150   | 4.42x              |

**Key Insight**: SVG rendering improved from 184 i/s to 424 i/s (+130%) after optimisations. The gap vs HTML reduced from 10x to 4.4x. Remaining gap is due to algorithmic complexity (edge detection + path tracing vs simple iteration).

### Performance by QR Code Size
*Note: Higher iterations/sec is better; lower std dev is better; lower slowdown is better*

#### SVG Export (End-to-end)
| Size   | Iterations/sec | Std Dev | Slowdown vs Small |
|--------|----------------|---------|-------------------|
| Small  | 102.7         | 1.00%   | 1.00x (baseline) |
| Medium | 32.2          | 0.00%   | 3.19x            |
| Large  | 10.9          | 0.00%   | 9.41x            |

#### PNG Export (End-to-end)
| Size   | Iterations/sec | Std Dev | Slowdown vs Small |
|--------|----------------|---------|-------------------|
| Small  | 102.5         | 1.00%   | 1.00x (baseline) |
| Medium | 33.6          | 0.00%   | 3.05x            |
| Large  | 11.4          | 0.00%   | 9.00x            |

#### HTML Export (End-to-end)
| Size   | Iterations/sec | Std Dev | Slowdown vs Small |
|--------|----------------|---------|-------------------|
| Small  | 109.2         | 3.70%   | 1.00x (baseline) |
| Medium | 34.2          | 0.00%   | 3.19x            |
| Large  | 11.6          | 0.00%   | 9.40x            |

#### ANSI Export (End-to-end)
| Size   | Iterations/sec | Std Dev | Slowdown vs Small |
|--------|----------------|---------|-------------------|
| Small  | 108.6         | 0.90%   | 1.00x (baseline) |
| Medium | 33.9          | 0.00%   | 3.21x            |
| Large  | 11.5          | 0.00%   | 9.42x            |

### Memory Allocations
*Note: Lower is better for both metrics*

| Format | Total Objects Allocated | Total Memory (MB) |
|--------|-------------------------|-------------------|
| HTML   | 451                    | 18.0              |
| PNG    | 357,676                | 23.1              |
| SVG    | 2,157,951              | 113.8             |

**Key Insights:**
- **End-to-end**: All formats now perform similarly (~32-34 i/s) - SVG optimisations closed the gap
- **Rendering-only**: HTML is fastest (1,876 i/s), SVG improved significantly (424 i/s, was 184 i/s)
- **SVG improvements**: +130% rendering speed, 71% memory reduction after 2026-01-08 optimisations
- **Optimisation priority**: Improvements to rqrcode_core have biggest impact on user experience
- **Format choice**: For high-volume rendering, HTML/ANSI are still faster but SVG is now competitive
- All formats show 3-10x performance degradation as QR size increases
- Memory usage: HTML uses 6x less memory than SVG (was 22x before optimisation)

## Notes

- **Primary metric**: End-to-end results reflect real user experience
- **Secondary metric**: Rendering-only helps diagnose where to optimise
- Focus on relative comparisons, not absolute numbers
- Results vary by system (CPU, Ruby version, rqrcode_core version)
- Run benchmarks before and after making changes to measure impact
- Full suite runs in ~2-3 minutes (doubled due to two modes per benchmark)
- When rqrcode_core updates, expect end-to-end improvements even without changes to this gem
