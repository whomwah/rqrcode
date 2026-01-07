# RQRCode Development Guide for AI Agents

## Build/Test/Lint Commands
- `bundle install` - Install dependencies
- `rake` - Run all specs and auto-fix linting (default task)
- `rake spec` - Run all specs
- `bundle exec rspec spec/path/to/file_spec.rb` - Run a single test file
- `bundle exec rspec spec/path/to/file_spec.rb:42` - Run single test at line 42
- `rake standard` - Check code style
- `rake standard:fix` - Auto-fix code style issues
- `./bin/console` - Launch interactive console

## Code Style (Standard RB)
- Follow [Standard Ruby](https://github.com/testdouble/standard) style guide (enforced via `standard` gem)
- Ruby version: >= 3.0.0
- Always use `# frozen_string_literal: true` at the top of all Ruby files
- Use double quotes for strings
- Use snake_case for variables/methods, SCREAMING_SNAKE_CASE for constants
- 2-space indentation
- No trailing whitespace
- Module structure: `lib/rqrcode/` for implementation, `spec/rqrcode/` for tests

## File Structure & Naming
- Implementation: `lib/rqrcode/<feature>.rb` or `lib/rqrcode/<namespace>/<feature>.rb`
- Tests: `spec/rqrcode/<feature>_spec.rb` (must end with `_spec.rb`)
- Export modules live in `lib/rqrcode/export/` (e.g., `svg.rb`, `png.rb`, `ansi.rb`)

## Testing
- Use RSpec for all tests
- Test files require `spec_helper` at the top
- Use `describe` blocks for grouping related tests
- Use `it` blocks for individual test cases
- Tests should verify behavior, not implementation details

## Dependencies
- Core QR generation: `rqrcode_core` gem (do not modify, separate project)
- PNG rendering: `chunky_png` gem
- This gem focuses on rendering QR codes from `rqrcode_core` data structures

## Commit Messages

Use the Semantic Commit Message style:

- **type**: The type of change (see below)
- **scope**: Optional, the area of the codebase affected (e.g., `auth`, `api`, `ui`)
- **subject**: A brief description in imperative mood, lowercase, no full stop
