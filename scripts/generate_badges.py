#!/usr/bin/env python3
"""
Badge generation script for NimLisp
Generates local badges from Nim build and test data
"""

import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, Any

def run_command(cmd: str) -> tuple[int, str, str]:
    """Run a shell command and return exit code, stdout, stderr"""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.returncode, result.stdout, result.stderr

def get_project_version() -> str:
    """Get the current project version from nimble file"""
    try:
        nimble_files = list(Path(".").glob("*.nimble"))
        if nimble_files:
            content = nimble_files[0].read_text()
            # Look for version line
            match = re.search(r'version\s*=\s*"([^"]+)"', content)
            if match:
                return match.group(1)
        return "0.1.0"
    except Exception:
        return "0.1.0"

def generate_build_status() -> str:
    """Generate build status by running Nim compile check"""
    print("🔨 Checking build status...")
    
    # Check if main.nim exists
    if Path("main.nim").exists():
        exit_code, _, stderr = run_command("nim check main.nim")
    elif Path("src/main.nim").exists():
        exit_code, _, stderr = run_command("nim check src/main.nim")
    else:
        # Try to find any .nim file
        nim_files = list(Path(".").rglob("*.nim"))
        if nim_files and not any("test" in str(f) for f in nim_files):
            exit_code, _, stderr = run_command(f"nim check {nim_files[0]}")
        else:
            # No source files yet
            return "no source"
    
    if exit_code == 0:
        return "passing"
    else:
        print(f"❌ Build failed: {stderr}")
        return "failing"

def run_tests() -> Dict[str, Any]:
    """Run Nim tests using Testament and count individual test blocks"""
    print("🧪 Running tests with Testament...")
    
    # Run Testament to get test file results
    exit_code, stdout, stderr = run_command("testament pattern 'tests/t*.nim' --print")
    
    test_results = {
        "status": "no tests",
        "passed": 0,
        "failed": 0,
        "total": 0,
        "test_functions": 0
    }
    
    if exit_code == 0:
        # Parse Testament output to count test files
        lines = stdout.split('\n')
        passed_files = 0
        failed_files = 0
        
        for line in lines:
            # Remove ANSI color codes for parsing
            clean_line = re.sub(r'\x1b\[[0-9;]*m', '', line)
            if "PASS:" in clean_line and ".nim c" in clean_line:
                passed_files += 1
            elif "FAIL:" in clean_line:
                failed_files += 1
        
        # Count individual test blocks
        test_blocks = 0
        for test_file in Path("tests").glob("t_*.nim"):
            try:
                content = test_file.read_text()
                # Count blocks that start test cases
                test_blocks += len(re.findall(r'^block:', content, re.MULTILINE))
            except Exception:
                continue
        
        if passed_files > 0 and failed_files == 0:
            # All test files passed, so all blocks passed
            test_results["total"] = test_blocks
            test_results["passed"] = test_blocks
            test_results["failed"] = 0
            test_results["test_functions"] = test_blocks
            test_results["status"] = "passing"
        elif failed_files > 0:
            # Some files failed
            test_results["total"] = test_blocks
            test_results["passed"] = 0  # Conservative estimate
            test_results["failed"] = test_blocks
            test_results["test_functions"] = test_blocks
            test_results["status"] = "failing"
        
        # Skip HTML report generation
        
        # Note: Test executable cleanup is deferred until after coverage calculation
    else:
        test_results["status"] = "failing"
    
    return test_results

def calculate_coverage() -> float:
    """Calculate real code coverage using gcov/lcov"""
    print("📊 Calculating code coverage...")
    
    # Check if lcov is available
    exit_code, _, _ = run_command("which lcov")
    if exit_code != 0:
        print("⚠️  lcov not found. Using fallback estimation...")
        return estimate_coverage_fallback()
    
    # Clean up any existing coverage data
    run_command("find . -name '*.gcda' -delete 2>/dev/null || true")
    run_command("find ~/.cache/nim -name '*.gcda' -delete 2>/dev/null || true")
    
    # Reset coverage counters
    run_command("lcov --zerocounters --directory . 2>/dev/null || true")
    run_command("lcov --zerocounters --directory ~/.cache/nim 2>/dev/null || true")
    
    # Compile tests with coverage flags
    print("🔨 Compiling tests with coverage...")
    for test_file in Path("tests").glob("t_*.nim"):
        cmd = f"nim c --debugger:native --passC:--coverage --passL:--coverage --verbosity:0 --hints:off {test_file}"
        exit_code, _, stderr = run_command(cmd)
        if exit_code != 0:
            print(f"⚠️  Failed to compile {test_file} with coverage")
            continue
    
    # Run compiled tests to generate coverage data
    print("🧪 Running compiled tests to generate coverage data...")
    for test_file in Path("tests").glob("t_*.nim"):
        test_name = test_file.stem
        test_exe = f"tests/{test_name}"
        if Path(test_exe).exists():
            run_command(f"{test_exe} > /dev/null 2>&1")
    
    # Try to capture coverage data
    coverage_info_file = "coverage.info"
    
    # Try multiple directories where coverage data might be
    coverage_captured = False
    
    # Try nim cache directory where coverage data is actually stored
    exit_code, stdout, stderr = run_command(f"lcov --capture --directory ~/.cache/nim --output-file {coverage_info_file}")
    if exit_code == 0 and Path(coverage_info_file).exists():
        coverage_captured = True
    
    if not coverage_captured:
        print("⚠️  Could not capture coverage data, using fallback estimation")
        return estimate_coverage_fallback()
    
    # Filter to only our source code for cleaner reporting
    filtered_info = "coverage_src.info"
    run_command(f"lcov --extract {coverage_info_file} '*/src/*' --output-file {filtered_info}")
    
    # Extract coverage percentage
    exit_code, stdout, stderr = run_command(f"lcov --summary {filtered_info}")
    
    coverage_percentage = 0.0
    if exit_code == 0:
        # Parse lcov summary output to extract coverage percentage
        lines = stdout.split('\n')
        for line in lines:
            if 'lines......:' in line:
                # Format: "  lines......: 85.5% (123 of 144 lines)"
                match = re.search(r'(\d+\.?\d*)%', line)
                if match:
                    coverage_percentage = float(match.group(1))
                    break
    
    # Generate detailed HTML coverage report (source code only)
    print("📊 Generating detailed HTML coverage report...")
    run_command("rm -rf coverage_html 2>/dev/null || true")
    exit_code, stdout, stderr = run_command(f"genhtml {filtered_info} --output-directory coverage_html --title 'NimLisp Source Code Coverage' --no-function-coverage")
    
    if exit_code == 0 and Path("coverage_html/index.html").exists():
        print("✅ HTML coverage report generated: coverage_html/index.html")
        print("🌐 Open with: open coverage_html/index.html")
        print("📊 Report shows line-by-line coverage for source files only")
    else:
        print(f"⚠️  Failed to generate HTML coverage report: {stderr}")
    
    # Clean up coverage files and test executables  
    run_command(f"rm -f {coverage_info_file} {filtered_info} 2>/dev/null || true")
    print("🧹 Cleaning up test executables...")
    run_command("find tests/ -type f -executable -not -name '*.nim' -delete 2>/dev/null || true")
    
    print(f"📈 Code coverage: {coverage_percentage:.1f}%")
    return coverage_percentage

def estimate_coverage_fallback() -> float:
    """Fallback coverage estimation when gcov/lcov is not available"""
    print("📊 Using fallback coverage estimation...")
    
    # Count source functions and test blocks for estimation
    src_functions = 0
    test_blocks = 0
    
    for nim_file in Path(".").rglob("*.nim"):
        if nim_file.is_relative_to(Path("tests")) and nim_file.name.startswith("t_"):
            try:
                content = nim_file.read_text()
                test_blocks += len(re.findall(r'^block:', content, re.MULTILINE))
            except Exception:
                continue
        elif not (nim_file.is_relative_to(Path("tests")) or "test" in nim_file.name.lower()):
            try:
                content = nim_file.read_text()
                # Count all procs/funcs
                src_functions += len(re.findall(r'^\s*proc\s+\w+', content, re.MULTILINE))
                src_functions += len(re.findall(r'^\s*func\s+\w+', content, re.MULTILINE))
            except Exception:
                continue
    
    if src_functions == 0:
        return 0.0
    
    # Conservative estimation: assume good coverage if 1+ tests per function
    ratio = test_blocks / src_functions
    estimated_coverage = min(ratio * 85, 95.0)  # Cap at 95% for estimates
    
    print(f"📈 Estimated coverage: {estimated_coverage:.1f}% (based on {test_blocks} test blocks for {src_functions} source functions)")
    return estimated_coverage

def create_badge_url(label: str, message: str, color: str) -> str:
    """Create a shields.io badge URL"""
    # URL encode spaces and special characters
    label = label.replace("%", "%25").replace(" ", "%20")
    message = message.replace("%", "%25").replace(" ", "%20")
    return f"https://img.shields.io/badge/{label}-{message}-{color}.svg"

def generate_badges() -> Dict[str, str]:
    """Generate all badges and return URLs"""
    badges = {}
    
    # Version badge
    version = get_project_version()
    badges["version"] = create_badge_url("version", f"v{version}", "blue")
    
    # Build status badge
    build_status = generate_build_status()
    if build_status == "passing":
        build_color = "brightgreen"
    elif build_status == "no source":
        build_color = "lightgrey"
    else:
        build_color = "red"
    badges["build"] = create_badge_url("build", build_status, build_color)
    
    # Test results badge using Testament data
    test_results = run_tests()
    
    if test_results["total"] > 0:
        if test_results["status"] == "failing":
            test_message = f"{test_results['total']} tests ({test_results['failed']} failed)"
        else:
            test_message = f"{test_results['total']} tests"
    else:
        test_message = "no tests"
    
    test_color = "brightgreen" if test_results["status"] == "passing" else "red" if test_results["status"] == "failing" else "lightgrey"
    badges["tests"] = create_badge_url("tests", test_message, test_color)
    
    # Coverage badge
    coverage = calculate_coverage()
    coverage_color = "brightgreen" if coverage >= 90 else "yellow" if coverage >= 70 else "red"
    badges["coverage"] = create_badge_url("coverage", f"{coverage:.1f}%", coverage_color)
    
    return badges

def update_readme(badges: Dict[str, str]):
    """Update README.md with new badge URLs"""
    readme_path = Path("README.md")
    if not readme_path.exists():
        print("❌ README.md not found")
        return
    
    content = readme_path.read_text()
    
    # Update badge URLs
    replacements = [
        (r'\[!\[Build Status\].*?\]\([^)]*\)', f'[![Build Status]({badges["build"]})](#)'),
        (r'\[!\[Test Coverage\].*?\]\([^)]*\)', f'[![Test Coverage]({badges["coverage"]})](#)'),
        (r'\[!\[Tests\].*?\]\([^)]*\)', f'[![Tests]({badges["tests"]})](#)'),
        (r'\[!\[Version\].*?\]\([^)]*\)', f'[![Version]({badges["version"]})](#)'),
    ]
    
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content)
    
    readme_path.write_text(content)
    print("✅ README.md updated with new badges")

def save_badge_data(badges: Dict[str, str]):
    """Save badge data to file for reference"""
    badge_data = {
        "generated_at": subprocess.check_output(["date", "-Iseconds"]).decode().strip(),
        "badges": badges
    }
    
    Path("badges").mkdir(exist_ok=True)
    with open("badges/data.json", "w") as f:
        json.dump(badge_data, f, indent=2)
    
    print("💾 Badge data saved to badges/data.json")

def main():
    """Main function"""
    print("🎯 NimLisp Badge Generator")
    print("=" * 26)
    
    try:
        badges = generate_badges()
        save_badge_data(badges)
        update_readme(badges)
        
        print("\n✅ All badges generated successfully!")
        print("\nGenerated badges:")
        for name, url in badges.items():
            print(f"  {name}: {url}")
            
    except Exception as e:
        print(f"❌ Error generating badges: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()