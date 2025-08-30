# TYPO3 Auto-Install Test Suite

This directory contains the comprehensive test suite for the TYPO3 auto-install project. The test suite validates installation scripts, sitepackage generation, error handling, and cross-platform compatibility.

## Table of Contents

- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Test Categories](#test-categories)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Running Tests](#running-tests)
- [Test Data & Fixtures](#test-data--fixtures)
- [Reports & Results](#reports--results)
- [Development Guidelines](#development-guidelines)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Quick Start

**Run all tests:**
```bash
./tests/run-tests.sh
```

**Run specific test category:**
```bash
./tests/run-tests.sh --category unit
./tests/run-tests.sh --category integration
./tests/run-tests.sh --category compatibility
```

**Run with verbose output and generate report:**
```bash
./tests/run-tests.sh --verbose --report
```

## Directory Structure

```
tests/
├── README.md                           # This comprehensive testing guide
├── run-tests.sh                        # Master test runner script
├── generate-report.sh                  # Report generation utility
├── test-reporting-system.sh            # Test reporting system
├── script-analysis.md                  # Script analysis documentation
├── unit/                               # Unit tests for individual functions
│   ├── test_replacement_units.sh       # Tests replacement function components
│   ├── test_simple_permissions.sh      # Tests basic permission handling
│   ├── test_units/                     # Unit test fixtures
│   └── test_simple_permissions/        # Permission test fixtures
├── integration/                        # Integration tests for complete workflows
│   ├── test_real_sitepackage.sh        # Tests actual sitepackage replacement
│   └── test_permission_preservation.sh # Tests file permission preservation
├── compatibility/                      # Cross-platform and version compatibility
│   ├── test_bash_compatibility.sh      # Cross-platform bash compatibility
│   ├── test_bash_version_compatibility.sh # Bash version compatibility
│   └── run_all_compatibility_tests.sh  # Master compatibility runner
├── error-handling/                     # Error handling and recovery tests
│   └── test_replacement_error_handling.sh # Comprehensive error handling tests
├── development/                        # Development and debugging utilities
│   ├── debug_validation.sh             # Debug validation functions
│   ├── debug_hyphen_test.sh            # Debug hyphenated project names
│   ├── test_replacement_quick.sh       # Quick development testing
│   └── extract_replacement_functions.sh # Function extraction utility
├── lib/                                # Shared utilities and libraries
│   ├── README.md                       # Path utilities documentation
│   ├── path-utils.sh                   # Core path resolution functions
│   ├── test-path-utils.sh              # Path utilities test suite
│   ├── test-reporting.sh               # Test reporting functions
│   ├── example-usage.sh                # Usage examples
│   └── validate-cross-directory.sh     # Cross-directory validation
├── fixtures/                           # Test data and fixtures
│   └── test_error_handling/            # Error handling test data
│       ├── concurrent/                 # Concurrent access test files
│       ├── corrupted/                  # Corrupted file test data
│       ├── permissions/                # Permission test files
│       ├── recovery/                   # Recovery test scenarios
│       ├── resources/                  # General test resources
│       ├── stress/                     # Stress test data
│       └── symlinks/                   # Symbolic link test data
└── reports/                            # Test result outputs and reports
    ├── test_results/                   # Historical test results
    └── test_validation/                # Validation reports
```

## Test Categories

### Unit Tests (`tests/unit/`)

**Purpose:** Test individual functions and components in isolation to ensure they work correctly independently.

**Scripts:**
- `test_replacement_units.sh` - Tests replacement function components, validation logic, and helper functions
- `test_simple_permissions.sh` - Tests basic file permission handling and preservation

**When to run:** During development of new functions or when modifying existing replacement logic.

**Example usage:**
```bash
# Run all unit tests
./tests/run-tests.sh --category unit

# Run specific unit test
./tests/unit/test_replacement_units.sh

# Run with verbose output
./tests/run-tests.sh --category unit --verbose
```

### Integration Tests (`tests/integration/`)

**Purpose:** Test complete workflows and real-world scenarios to ensure all components work together correctly.

**Scripts:**
- `test_real_sitepackage.sh` - Tests actual sitepackage replacement with real TYPO3 template files
- `test_permission_preservation.sh` - Tests that file permissions are correctly preserved during installation

**When to run:** Before releases, after major changes, or when testing complete installation workflows.

**Example usage:**
```bash
# Run all integration tests
./tests/run-tests.sh --category integration

# Run specific integration test
./tests/integration/test_real_sitepackage.sh
```

### Compatibility Tests (`tests/compatibility/`)

**Purpose:** Ensure cross-platform and version compatibility across different operating systems and bash versions.

**Scripts:**
- `test_bash_compatibility.sh` - Tests cross-platform bash compatibility (macOS, Linux)
- `test_bash_version_compatibility.sh` - Tests compatibility with different bash versions (3.2+, 4.0+)
- `run_all_compatibility_tests.sh` - Master runner for all compatibility tests

**When to run:** Before releases, when adding new bash features, or when supporting new platforms.

**Example usage:**
```bash
# Run all compatibility tests
./tests/run-tests.sh --category compatibility

# Run specific compatibility test
./tests/compatibility/test_bash_compatibility.sh

# Run compatibility suite
./tests/compatibility/run_all_compatibility_tests.sh
```

### Error Handling Tests (`tests/error-handling/`)

**Purpose:** Validate error conditions, recovery mechanisms, and edge cases to ensure robust operation.

**Scripts:**
- `test_replacement_error_handling.sh` - Comprehensive error handling tests including file corruption, permission issues, and recovery scenarios

**When to run:** When modifying error handling logic, before releases, or when investigating reported issues.

**Example usage:**
```bash
# Run all error handling tests
./tests/run-tests.sh --category error-handling

# Run specific error handling test
./tests/error-handling/test_replacement_error_handling.sh
```

### Development Tools (`tests/development/`)

**Purpose:** Debugging and development utilities for troubleshooting and rapid testing during development.

**Scripts:**
- `debug_validation.sh` - Debug validation functions and test environment setup
- `debug_hyphen_test.sh` - Debug hyphenated project names and special character handling
- `test_replacement_quick.sh` - Quick development testing for rapid iteration
- `extract_replacement_functions.sh` - Function extraction utility for code analysis

**When to run:** During active development, debugging issues, or when creating new test scenarios.

**Example usage:**
```bash
# Run development tools
./tests/run-tests.sh --category development

# Run quick test during development
./tests/development/test_replacement_quick.sh

# Debug validation issues
./tests/development/debug_validation.sh
```

## Prerequisites

### System Requirements

**Operating System:**
- macOS 10.15+ (with Bash 3.2+ default)
- Linux distributions with Bash 3.2+
- Windows with WSL2 (Ubuntu/Debian recommended)

**Required Software:**
- **Bash:** Version 3.2+ (macOS default) or 4.0+ (Linux default)
- **DDEV:** Latest version for TYPO3 development
- **PHP:** 8.3+ (managed by DDEV)
- **Composer:** Latest version
- **Git:** For version control operations

**Optional but Recommended:**
- **Node.js:** 18+ for Vite asset compilation
- **npm/yarn:** For frontend dependency management

### Project Requirements

**TYPO3 Template Structure:**
- TYPO3 installation template in `install-src/xxxx_sitepackage/`
- Valid `install.config` file in project root
- Main installation scripts (`install-typo3.sh`, `create-sitepackage.sh`)

**File Permissions:**
- Read/write permissions in `tests/` directory
- Execute permissions on test scripts
- Write permissions in `tests/reports/` for result generation

**Environment Variables:**
- `PROJECT_NAME` (optional, can be set in `install.config`)
- `TYPO3_VERSION` (optional, defaults to latest stable)

## Installation & Setup

### 1. Verify Prerequisites

```bash
# Check bash version
bash --version

# Check DDEV installation
ddev version

# Check PHP version (via DDEV)
ddev php --version

# Verify project structure
ls -la install-src/xxxx_sitepackage/
```

### 2. Set Up Test Environment

```bash
# Navigate to project root
cd /path/to/typo3-auto-install

# Ensure test scripts are executable
chmod +x tests/run-tests.sh
chmod +x tests/*/test_*.sh
chmod +x tests/*/debug_*.sh
chmod +x tests/*/run_*.sh

# Create reports directory if it doesn't exist
mkdir -p tests/reports

# Verify path resolution works
./tests/lib/test-path-utils.sh
```

### 3. Validate Installation

```bash
# Run a quick validation test
./tests/development/debug_validation.sh

# Test path resolution from different directories
cd tests/unit && ../../lib/test-path-utils.sh
cd ../..

# Verify all test categories are accessible
./tests/run-tests.sh --list
```

## Running Tests

### Master Test Runner

The `tests/run-tests.sh` script provides a unified interface for executing all tests:

```bash
# Basic usage
./tests/run-tests.sh [OPTIONS]

# Available options:
#   -c, --category CATEGORY    Run specific category (unit, integration, compatibility, error-handling, development)
#   -v, --verbose             Enable verbose output
#   -r, --report              Generate detailed text report
#   -j, --json                Generate JSON report
#   -s, --summary             Generate summary from existing reports
#   -l, --list               List available test categories
#   -h, --help               Show help message
```

### Common Usage Patterns

**Development Workflow:**
```bash
# Quick unit tests during development
./tests/run-tests.sh --category unit --verbose

# Full integration test before commit
./tests/run-tests.sh --category integration --report

# Complete test suite before release
./tests/run-tests.sh --verbose --report --json
```

**Debugging Issues:**
```bash
# Run specific test with verbose output
./tests/unit/test_replacement_units.sh

# Debug environment issues
./tests/development/debug_validation.sh

# Test path resolution
./tests/lib/test-path-utils.sh
```

**Continuous Integration:**
```bash
# CI-friendly test run with reports
./tests/run-tests.sh --report --json

# Compatibility validation
./tests/run-tests.sh --category compatibility --report

# Error handling validation
./tests/run-tests.sh --category error-handling --verbose
```

### Individual Test Execution

Each test script can be run independently:

```bash
# Unit tests
./tests/unit/test_replacement_units.sh
./tests/unit/test_simple_permissions.sh

# Integration tests
./tests/integration/test_real_sitepackage.sh
./tests/integration/test_permission_preservation.sh

# Compatibility tests
./tests/compatibility/test_bash_compatibility.sh
./tests/compatibility/test_bash_version_compatibility.sh

# Error handling tests
./tests/error-handling/test_replacement_error_handling.sh

# Development tools
./tests/development/debug_validation.sh
./tests/development/test_replacement_quick.sh
```

### Test Categories by Use Case

**Before Code Changes:**
```bash
# Run relevant unit tests
./tests/run-tests.sh --category unit

# Quick integration check
./tests/development/test_replacement_quick.sh
```

**Before Committing:**
```bash
# Full test suite
./tests/run-tests.sh --verbose

# Generate report for review
./tests/run-tests.sh --report
```

**Before Releasing:**
```bash
# Complete validation with all reports
./tests/run-tests.sh --verbose --report --json --summary

# Platform compatibility check
./tests/run-tests.sh --category compatibility --verbose
```

**Debugging Issues:**
```bash
# Error handling validation
./tests/run-tests.sh --category error-handling --verbose

# Development debugging
./tests/run-tests.sh --category development --verbose
```

## Test Data & Fixtures

### Fixtures Directory Structure

The `tests/fixtures/` directory contains test data organized by purpose:

```
fixtures/
├── test_error_handling/           # Error handling test scenarios
│   ├── concurrent/               # Concurrent access test files (20 files)
│   ├── corrupted/               # Corrupted file test data
│   │   ├── fake_binary.png      # Binary file for testing
│   │   ├── large.txt           # Large file for stress testing
│   │   ├── longline.txt        # File with extremely long lines
│   │   ├── normal.txt          # Normal test file
│   │   └── nullbytes.txt       # File with null bytes
│   ├── permissions/            # Permission test files
│   │   ├── noread.txt         # File without read permissions
│   │   ├── normal.txt         # Normal file with standard permissions
│   │   └── readonly.txt       # Read-only file
│   ├── recovery/              # Recovery test scenarios
│   │   ├── complex_file.txt   # Complex file for recovery testing
│   │   └── test_file.txt      # Simple recovery test file
│   ├── resources/             # General test resources (100 files)
│   ├── stress/                # Stress test data (200+ files)
│   └── symlinks/              # Symbolic link test data
└── test_permission_preservation/ # Permission preservation test data
```

### Using Test Fixtures

**In Unit Tests:**
```bash
# Access unit test fixtures
TEST_FIXTURES="$(resolve_tests_path "fixtures")"
UNIT_TEST_DATA="$TEST_FIXTURES/test_units"

# Use specific test files
NORMAL_FILE="$TEST_FIXTURES/test_error_handling/corrupted/normal.txt"
LARGE_FILE="$TEST_FIXTURES/test_error_handling/corrupted/large.txt"
```

**In Integration Tests:**
```bash
# Access integration test fixtures
PERMISSION_TEST_DATA="$(resolve_tests_path "fixtures/test_permission_preservation")"
ERROR_TEST_DATA="$(resolve_tests_path "fixtures/test_error_handling")"

# Test with real sitepackage template
SITEPACKAGE_TEMPLATE="$(resolve_project_path "install-src/xxxx_sitepackage")"
```

**In Error Handling Tests:**
```bash
# Access error handling fixtures
ERROR_FIXTURES="$(resolve_tests_path "fixtures/test_error_handling")"
CORRUPTED_FILES="$ERROR_FIXTURES/corrupted"
PERMISSION_FILES="$ERROR_FIXTURES/permissions"
STRESS_FILES="$ERROR_FIXTURES/stress"
```

### Creating New Test Fixtures

When adding new test scenarios:

1. **Organize by purpose:** Place fixtures in appropriate subdirectories
2. **Use descriptive names:** Make file purposes clear from names
3. **Document special cases:** Add comments for unusual test conditions
4. **Maintain permissions:** Ensure test files have correct permissions for testing
5. **Update documentation:** Document new fixtures in relevant test scripts

## Reports & Results

### Report Types

**Text Reports (`*.txt`):**
- Human-readable format
- Detailed test execution logs
- Error messages and stack traces
- Summary statistics

**JSON Reports (`*.json`):**
- Machine-readable format
- Structured test result data
- Integration with CI/CD systems
- Programmatic analysis

**Summary Reports:**
- Aggregated results from multiple test runs
- Trend analysis over time
- Historical comparison data

### Report Generation

**Generate reports during test execution:**
```bash
# Text report
./tests/run-tests.sh --report

# JSON report
./tests/run-tests.sh --json

# Both formats
./tests/run-tests.sh --report --json

# Summary from existing reports
./tests/run-tests.sh --summary
```

**Manual report generation:**
```bash
# Generate report from existing results
./tests/generate-report.sh

# Test the reporting system
./tests/test-reporting-system.sh
```

### Report Locations

Reports are saved in `tests/reports/` with timestamps:

```
reports/
├── test_run_report_YYYYMMDD_HHMMSS.txt    # Text reports
├── test_run_report_YYYYMMDD_HHMMSS.json   # JSON reports
├── test_summary_YYYYMMDD_HHMMSS.txt       # Summary reports
├── bash_compatibility_YYYYMMDD_HHMMSS.log # Compatibility logs
├── bash_version_YYYYMMDD_HHMMSS.log       # Version compatibility logs
└── test_results/                          # Historical results
    └── [various timestamped files]
```

### Interpreting Results

**Test Status Codes:**
- `PASS` - Test completed successfully
- `FAIL` - Test failed with errors
- `SKIP` - Test was skipped (missing dependencies)
- `ERROR` - Test could not execute (script errors)

**Exit Codes:**
- `0` - All tests passed
- `1` - One or more tests failed
- `2` - Test execution error
- `3` - Invalid arguments or configuration

## Development Guidelines

### Writing New Tests

**Test Script Structure:**
```bash
#!/bin/bash

# Test Description and Metadata
# Test Category: unit|integration|compatibility|error-handling|development
# Requirements: List of requirement IDs this test validates

set -e

# Source path utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

# Validate test environment
validate_test_environment "category_name"

# Resolve project paths
PROJECT_ROOT="$(resolve_project_root)"
if [ $? -ne 0 ]; then
    echo "ERROR: Could not locate project root directory"
    exit 1
fi

# Test implementation
# ... test logic here ...

# Exit with appropriate code
exit 0
```

**Best Practices:**
1. **Use path utilities:** Always use the standardized path resolution functions
2. **Validate environment:** Check that the test can run in the current environment
3. **Handle errors gracefully:** Provide clear error messages and appropriate exit codes
4. **Document requirements:** Link tests to specific requirements they validate
5. **Use consistent logging:** Follow the established logging patterns
6. **Clean up resources:** Remove temporary files and restore state

### Modifying Existing Tests

**Before modifying:**
1. Run the existing test to understand current behavior
2. Review the test's requirements and purpose
3. Check for dependencies on other tests or components

**During modification:**
1. Maintain backward compatibility where possible
2. Update documentation if test behavior changes
3. Ensure all requirements are still validated
4. Test modifications across different platforms

**After modification:**
1. Run the modified test in isolation
2. Run the full test suite to check for regressions
3. Update any dependent tests or documentation
4. Generate reports to verify expected behavior

### Adding New Test Categories

To add a new test category:

1. **Create directory:** `mkdir tests/new-category`
2. **Update master runner:** Add category to `tests/run-tests.sh`
3. **Add documentation:** Update this README with category description
4. **Create test scripts:** Follow established patterns and conventions
5. **Test integration:** Ensure new category works with existing infrastructure

## Troubleshooting

### Common Issues

**Path Resolution Errors:**
```
ERROR: Could not locate project root directory
```
**Solution:** Ensure you're running tests from within the project directory structure and that key project files (`install-typo3.sh`, `create-sitepackage.sh`) exist in the project root.

**Permission Denied Errors:**
```
bash: ./tests/run-tests.sh: Permission denied
```
**Solution:** Make test scripts executable:
```bash
chmod +x tests/run-tests.sh
chmod +x tests/*/test_*.sh
```

**Missing Dependencies:**
```
ERROR: Could not source required functions
```
**Solution:** Ensure all required project files exist and are accessible:
```bash
ls -la install-typo3.sh create-sitepackage.sh
```

**Test Fixture Access Issues:**
```
ERROR: Test fixtures not found
```
**Solution:** Verify test fixtures exist and are accessible:
```bash
ls -la tests/fixtures/
./tests/lib/test-path-utils.sh
```

### Debugging Steps

**1. Verify Environment:**
```bash
# Check bash version
bash --version

# Verify project structure
ls -la install-typo3.sh create-sitepackage.sh

# Test path resolution
./tests/lib/test-path-utils.sh
```

**2. Run Diagnostic Tests:**
```bash
# Environment validation
./tests/development/debug_validation.sh

# Path resolution debugging
./tests/lib/test-path-utils.sh --verbose

# Quick functionality test
./tests/development/test_replacement_quick.sh
```

**3. Check Specific Issues:**
```bash
# Permission issues
ls -la tests/fixtures/test_error_handling/permissions/

# Compatibility issues
./tests/compatibility/test_bash_compatibility.sh

# Error handling
./tests/error-handling/test_replacement_error_handling.sh --verbose
```

### Platform-Specific Issues

**macOS (Bash 3.2):**
- Some bash 4+ features may not work
- Use POSIX-compatible syntax where possible
- Test with both system bash and newer versions

**Linux (Bash 4.0+):**
- Generally more feature-complete
- May have different command behaviors (GNU vs BSD)
- Test cross-platform compatibility

**Windows (WSL):**
- Path resolution may behave differently
- File permissions may not work as expected
- Use Linux-compatible approaches

### Getting Help

**Debug Information:**
```bash
# Generate comprehensive debug info
./tests/development/debug_validation.sh --verbose

# Test environment validation
./tests/lib/test-path-utils.sh --debug

# Generate diagnostic report
./tests/run-tests.sh --category development --verbose --report
```

**Log Analysis:**
```bash
# Check recent test reports
ls -la tests/reports/test_run_report_*.txt

# View latest report
cat tests/reports/test_run_report_*.txt | tail -1

# Search for specific errors
grep -r "ERROR" tests/reports/
```

## Contributing

### Adding New Tests

1. **Identify the test category** (unit, integration, compatibility, error-handling, development)
2. **Create the test script** following established patterns
3. **Add test fixtures** if needed in `tests/fixtures/`
4. **Update documentation** in this README
5. **Test the new test** across different platforms
6. **Submit for review** with clear description of what the test validates

### Improving Existing Tests

1. **Document the issue** or improvement opportunity
2. **Create a test case** that demonstrates the issue
3. **Implement the fix** following established patterns
4. **Verify the fix** doesn't break existing functionality
5. **Update documentation** if behavior changes

### Reporting Issues

When reporting test-related issues:

1. **Include environment information** (OS, bash version, DDEV version)
2. **Provide reproduction steps** with exact commands used
3. **Include error messages** and relevant log output
4. **Attach diagnostic information** from debug scripts
5. **Specify expected vs actual behavior**

### Code Review Guidelines

When reviewing test-related changes:

1. **Verify test coverage** - Does the test validate the intended functionality?
2. **Check error handling** - Are edge cases and error conditions covered?
3. **Validate documentation** - Is the test purpose and usage clearly documented?
4. **Test cross-platform** - Does the test work on different operating systems?
5. **Review integration** - Does the test work with the existing test infrastructure?

---

For additional information about the TYPO3 auto-install project, see the main project documentation and the individual test script comments.