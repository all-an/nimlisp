# NimLisp Makefile
# Build automation and badge generation for Nim

.PHONY: all build test fmt check clean badges full help setup

# Default target
all: build test

# Build the project
build:
	@echo "🔨 Building NimLisp..."
	nim c -r main.nim

# Run all tests
test:
	@echo "🧪 Running tests..."
	@testament pattern "tests/t*.nim" --print
	@echo "🧹 Cleaning up test executables..."
	@find tests/ -type f -executable -not -name "*.nim" -delete 2>/dev/null || true

# Format all source files
fmt:
	@echo "🎨 Formatting code..."
	find . -name "*.nim" -exec nimpretty {} \; || echo "nimpretty not available"

# Check code quality
check:
	@echo "🔍 Checking code quality..."
	nim check src/*.nim || echo "No source files to check yet"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf nimcache/
	@rm -rf coverage_html/
	@rm -rf badges/data.json
	@rm -f coverage*.info
	@find tests/ -type f -executable -not -name "*.nim" -delete 2>/dev/null || true
	@find . -name "*.exe" -delete
	@find . -name "main" -delete

# Generate badges only
badges:
	@echo "🎯 Generating badges..."
	@python3 scripts/generate_badges.py
	@echo "🧹 Cleaning up test executables..."
	@find tests/ -type f -executable -not -name "*.nim" -delete 2>/dev/null || true

# Full build pipeline: format, check, build, test, and generate badges
full: fmt check build test badges
	@echo "✅ Full build pipeline completed!"

# Run the main program
run: build
	@echo "🚀 Running NimLisp..."
	./main || ./main.exe

# Development setup
setup:
	@echo "🛠️ Setting up development environment..."
	@mkdir -p src
	@mkdir -p tests
	@mkdir -p scripts
	@mkdir -p badges
	@echo "Development environment ready!"

# Initialize nimble project if needed
init:
	@echo "📦 Initializing Nimble project..."
	@if [ ! -f "nimlisp.nimble" ]; then \
		echo "# Package\n\nversion       = \"0.1.0\"\nauthor        = \"Allan Pereira Abrahão\"\ndescription   = \"Pure functional, metaprogramming, homoiconic systems programming language\"\nlicense       = \"MIT\"\nsrcDir        = \"src\"\nbin           = @[\"nimlisp\"]\n\n# Dependencies\n\nrequires \"nim >= 1.6.0\"\n" > nimlisp.nimble; \
	fi

# Show help
help:
	@echo "NimLisp Build System"
	@echo "==================="
	@echo ""
	@echo "Available targets:"
	@echo "  build     - Compile the project"
	@echo "  test      - Run all tests"
	@echo "  fmt       - Format all source files"
	@echo "  check     - Check code quality"
	@echo "  run       - Build and run the main program"
	@echo "  badges    - Generate README badges"
	@echo "  full      - Complete build pipeline (fmt + check + build + test + badges)"
	@echo "  clean     - Clean build artifacts"
	@echo "  setup     - Set up development environment"
	@echo "  init      - Initialize Nimble project"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make          # Build and test"
	@echo "  make full     # Complete pipeline with badges"
	@echo "  make badges   # Update badges only"