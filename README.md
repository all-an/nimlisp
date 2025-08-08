# NimLisp

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](#)
[![Test Coverage](https://img.shields.io/badge/coverage-61.9%25-red.svg)](#)
[![Tests](https://img.shields.io/badge/tests-22%20tests-brightgreen.svg)](#)
[![Version](https://img.shields.io/badge/version-v0.1.0-blue.svg)](#)

A compiler for a pure functional, metaprogramming, homoiconic systems programming language, implemented in Nim.

## Vision

NimLisp aims to create a programming language that combines the best aspects of functional programming with systems-level control, featuring:

- **Pure Functional**: Immutable data structures, no side effects, referential transparency
- **Metaprogramming**: Powerful macro system allowing code generation and transformation
- **100% Homoiconic**: Code and data share identical S-expression representation
- **Systems Programming**: Direct memory control, zero-cost abstractions, compile-time optimizations

## Goals

Create a language where you can write high-performance systems code using pure functional paradigms, with a macro system as powerful as Lisp's but with modern type safety and performance characteristics.

## Roadmap

### Phase 1: Foundation
- [ ] S-expression lexer and parser
- [ ] Basic AST representation
- [ ] Simple evaluator for core forms
- [ ] REPL implementation

### Phase 2: Core Language
- [ ] Pure functional data structures (lists, vectors, maps)
- [ ] Lambda expressions and closures
- [ ] Pattern matching
- [ ] Basic type inference

### Phase 3: Metaprogramming
- [ ] Macro system with quote/unquote
- [ ] Compile-time code generation
- [ ] Macro expansion in REPL
- [ ] Reader macros

### Phase 4: Systems Programming
- [ ] Memory management primitives
- [ ] Raw pointer manipulation
- [ ] Unsafe operations for performance
- [ ] Compile-time evaluation

### Phase 5: Advanced Features
- [ ] Module system
- [ ] Advanced type system
- [ ] Optimization passes
- [ ] Standard library

## Architecture

The compiler follows a traditional pipeline:
```
Source Code → Lexer → Parser → Macro Expander → Type Checker → Code Generator → Target Code
```

Built with Nim for performance and targeting multiple backends (native, C, JavaScript).

## Development

### Building and Testing

```bash
# Clone the repository
git clone https://github.com/username/nimlisp.git
cd nimlisp

# Set up development environment
make setup

# Build the project
make build

# Run tests
make test

# Run the application
make run
```

### Using the Build System

We provide a comprehensive Makefile for development:

```bash
# Build and test (default)
make

# Complete build pipeline with badges
make full

# Run specific tasks
make build    # Compile only
make test     # Run tests only
make fmt      # Format code
make check    # Code quality check
make badges   # Update README badges
make clean    # Clean build artifacts
```

### Testing and Coverage

This project uses Testament for testing with real code coverage reporting via gcov/lcov. For detailed information about our testing approach, coverage reporting, and how to contribute tests, see [TESTING.md](TESTING.md).

**Quick Start:**
```bash
# Run all tests with Testament
make test

# Generate test coverage report and badges
make badges

# View HTML test results
open testresults.html

# View detailed line-by-line coverage report (after running badges)  
open coverage_html/index.html
```

### Badge System

The badges in the README are automatically generated from your local build and test data:

```bash
# Update badges from current build/test status
make badges

# Or run the script directly
python3 scripts/generate_badges.py
```

The badge system tracks:
- **Build Status**: Whether the project compiles successfully
- **Test Coverage**: Real line-by-line coverage using gcov/lcov
- **Tests**: Number of individual test blocks in Testament format
- **Version**: Current version from .nimble file

## License

MIT License - see LICENSE file for details.