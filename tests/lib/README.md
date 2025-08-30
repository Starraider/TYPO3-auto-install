# Path Resolution Utilities

This directory contains standardized path resolution utilities for test scripts that have been moved to the `tests/` directory structure.

## Overview

When test scripts are moved from the project root to subdirectories under `tests/`, they need a reliable way to:
- Find the project root directory
- Locate project files and dependencies
- Source shared functions and utilities
- Access test fixtures and data

The path resolution utilities provide a standardized solution that works across different execution contexts and platforms.

## Files

- `path-utils.sh` - Core path resolution functions
- `test-path-utils.sh` - Comprehensive test suite for the utilities
- `example-usage.sh` - Example demonstrating proper usage
- `README.md` - This documentation file

## Core Functions

### `resolve_project_root()`
Finds the project root directory by looking for key project files (`install-typo3.sh`, `create-sitepackage.sh`, etc.).

```bash
PROJECT_ROOT="$(resolve_project_root)"
echo "Project root: $PROJECT_ROOT"
```

### `get_script_directory()`
Returns the directory containing the calling script.

```bash
SCRIPT_DIR="$(get_script_directory)"
echo "Script directory: $SCRIPT_DIR"
```

### `resolve_project_path(relative_path)`
Resolves a path relative to the project root.

```bash
INSTALL_SCRIPT="$(resolve_project_path "install-typo3.sh")"
CONFIG_FILE="$(resolve_project_path "install.config")"
```

### `resolve_tests_path(relative_path)`
Resolves a path relative to the tests directory.

```bash
FIXTURES_DIR="$(resolve_tests_path "fixtures")"
REPORTS_DIR="$(resolve_tests_path "reports")"
```

### `source_project_file(file_path)`
Safely sources a file relative to the project root with error handling.

```bash
if source_project_file "replacement_functions_only.sh"; then
    echo "Successfully sourced replacement functions"
fi
```

### `validate_test_environment([category])`
Validates that the script is running from the expected test directory structure.

```bash
validate_test_environment "unit"  # Validates we're in tests/unit/
validate_test_environment         # General validation
```

## Usage Patterns

### Basic Setup in Test Scripts

```bash
#!/bin/bash

# Source path utilities (adjust relative path as needed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"  # From tests/unit/, tests/integration/, etc.
# OR
source "$SCRIPT_DIR/path-utils.sh"         # From tests/lib/

# Validate environment
validate_test_environment "unit"  # or "integration", "compatibility", etc.

# Resolve project paths
PROJECT_ROOT="$(resolve_project_root)"
INSTALL_SCRIPT="$(resolve_project_path "install-typo3.sh")"

# Source project functions
source_project_file "replacement_functions_only.sh"
```

### For Unit Tests (tests/unit/)

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

validate_test_environment "unit"

# Access test fixtures
TEST_FIXTURES="$(resolve_tests_path "fixtures")"
TEST_DATA="$TEST_FIXTURES/unit_test_data"
```

### For Integration Tests (tests/integration/)

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

validate_test_environment "integration"

# Access project files and test data
SITEPACKAGE_TEMPLATE="$(resolve_project_path "install-src/xxxx_sitepackage")"
TEST_RESULTS="$(resolve_tests_path "reports")"
```

### For Development Tools (tests/development/)

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

validate_test_environment "development"

# Access project files for debugging
PROJECT_ROOT="$(resolve_project_root)"
cd "$PROJECT_ROOT"  # Safe to change to project root
```

## Error Handling

All functions include proper error handling:

```bash
# Check if project root resolution succeeded
if ! PROJECT_ROOT="$(resolve_project_root)"; then
    echo "ERROR: Could not locate project root" >&2
    exit 1
fi

# Check if file sourcing succeeded
if ! source_project_file "some_functions.sh"; then
    echo "ERROR: Could not source required functions" >&2
    exit 1
fi
```

## Platform Compatibility

The utilities work across different platforms:
- **macOS**: Uses BSD-style commands where needed
- **Linux**: Uses GNU-style commands where needed
- **Different Bash versions**: Compatible with Bash 3.2+ (macOS default) and Bash 4.0+

## Caching

Path resolution results are cached for performance:
- First call resolves and caches the path
- Subsequent calls return cached result
- Use `clear_path_cache()` to reset if needed

## Testing

Run the comprehensive test suite:

```bash
./tests/lib/test-path-utils.sh
```

The test suite validates:
- Path resolution from different directories
- Error handling for invalid inputs
- Cross-platform compatibility
- Caching functionality
- Environment validation

## Migration Guide

When moving existing test scripts to use these utilities:

1. **Add path utilities import**:
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/../lib/path-utils.sh"
   ```

2. **Replace hardcoded paths**:
   ```bash
   # OLD
   source ./replacement_functions_only.sh
   TEST_DIR="test_units"
   
   # NEW
   source_project_file "replacement_functions_only.sh"
   TEST_DIR="$(resolve_tests_path "fixtures/test_units")"
   ```

3. **Add environment validation**:
   ```bash
   validate_test_environment "unit"  # or appropriate category
   ```

4. **Update relative path references**:
   ```bash
   # OLD
   if [ -f "install-typo3.sh" ]; then
   
   # NEW
   INSTALL_SCRIPT="$(resolve_project_path "install-typo3.sh")"
   if [ -f "$INSTALL_SCRIPT" ]; then
   ```

## Best Practices

1. **Always validate environment** at the start of test scripts
2. **Use absolute paths** resolved by the utilities rather than relative paths
3. **Handle errors** from path resolution functions
4. **Cache frequently used paths** in variables
5. **Use `source_project_file()`** instead of direct sourcing for better error handling

## Debugging

Use the debug function to troubleshoot path resolution issues:

```bash
debug_path_resolution        # Basic debug info
debug_path_resolution true   # Verbose debug info with environment details
```

This will show:
- Current working directory
- Script directory resolution
- Project root resolution
- Relative script path
- BASH_SOURCE array contents (verbose mode)
- Environment variables (verbose mode)