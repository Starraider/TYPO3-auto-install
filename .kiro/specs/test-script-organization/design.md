# Test Script Organization Design Document

## Overview

This design outlines the reorganization of test scripts in the TYPO3 auto-install project from a scattered structure in the root directory to a well-organized `tests/` directory with logical categorization, proper documentation, and maintained functionality.

## Architecture

### Directory Structure

The new test organization will follow this structure:

```
tests/
├── README.md                    # Comprehensive test documentation
├── run-tests.sh                 # Master test runner script
├── unit/                        # Unit tests for individual functions
│   ├── test_replacement_units.sh
│   └── test_simple_permissions.sh
├── integration/                 # Integration tests for complete workflows
│   ├── test_real_sitepackage.sh
│   └── test_permission_preservation.sh
├── compatibility/               # Cross-platform and version compatibility tests
│   ├── test_bash_compatibility.sh
│   ├── test_bash_version_compatibility.sh
│   └── run_all_compatibility_tests.sh
├── error-handling/              # Error handling and recovery tests
│   ├── test_replacement_error_handling.sh
│   └── test_error_handling/     # Test data directory (moved from root)
├── development/                 # Development and debugging utilities
│   ├── debug_validation.sh
│   ├── debug_hyphen_test.sh
│   ├── test_replacement_quick.sh
│   └── extract_replacement_functions.sh
├── fixtures/                    # Test data and fixtures
│   └── test_permission_preservation/ # Moved from root
└── reports/                     # Test result outputs
    └── test_results/            # Moved from root
```

### Script Categories

1. **Unit Tests**: Test individual functions in isolation
2. **Integration Tests**: Test complete workflows and real-world scenarios
3. **Compatibility Tests**: Ensure cross-platform and version compatibility
4. **Error Handling Tests**: Validate error conditions and recovery mechanisms
5. **Development Tools**: Debugging and development utilities

## Components and Interfaces

### Master Test Runner (`tests/run-tests.sh`)

The master test runner will provide a unified interface for executing tests:

```bash
# Run all tests
./tests/run-tests.sh

# Run specific category
./tests/run-tests.sh --category unit
./tests/run-tests.sh --category integration
./tests/run-tests.sh --category compatibility

# Run with verbose output
./tests/run-tests.sh --verbose

# Generate detailed report
./tests/run-tests.sh --report
```

### Path Resolution System

Each moved script will include a path resolution function to maintain compatibility:

```bash
# Function to resolve paths relative to project root
resolve_project_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$(cd "$script_dir/../.." && pwd)"
}

PROJECT_ROOT="$(resolve_project_root)"
```

### Test Data Management

Test data directories will be moved and scripts updated to reference new locations:
- `test_error_handling/` → `tests/fixtures/test_error_handling/`
- `test_permission_preservation/` → `tests/fixtures/test_permission_preservation/`
- `test_results/` → `tests/reports/test_results/`

## Data Models

### Test Script Metadata

Each test script will include standardized metadata:

```bash
# Test Metadata
TEST_NAME="Replacement Function Unit Tests"
TEST_CATEGORY="unit"
TEST_DESCRIPTION="Tests individual replacement function components"
TEST_DEPENDENCIES=("install-typo3.sh")
TEST_FIXTURES=("test_error_handling")
```

### Test Result Format

Standardized test result format for consistent reporting:

```bash
# Test Result Structure
{
    "test_name": "string",
    "category": "string", 
    "status": "pass|fail|skip",
    "duration": "number",
    "output": "string",
    "errors": ["string"]
}
```

## Error Handling

### Path Resolution Errors
- Validate that project root can be determined
- Provide clear error messages for missing dependencies
- Graceful fallback for missing test fixtures

### Missing Dependencies
- Check for required scripts before execution
- Validate that core installation scripts exist
- Provide helpful error messages for missing components

### Test Data Integrity
- Verify test fixtures exist before running tests
- Validate file permissions on test data
- Handle corrupted or missing test files gracefully

## Testing Strategy

### Migration Validation
1. **Pre-migration Testing**: Run all existing tests to establish baseline
2. **Post-migration Testing**: Verify all tests still pass after reorganization
3. **Path Validation**: Ensure all relative paths resolve correctly
4. **Permission Verification**: Confirm executable permissions are preserved

### Regression Testing
1. **Functionality Tests**: Verify core installation scripts still work
2. **Integration Tests**: Ensure test scripts can find and execute dependencies
3. **Cross-platform Tests**: Validate reorganization works on different systems

### Documentation Testing
1. **Command Verification**: Test all documented commands work as expected
2. **Example Validation**: Ensure all examples in documentation are accurate
3. **Completeness Check**: Verify documentation covers all test categories

## Implementation Phases

### Phase 1: Analysis and Planning
- Analyze existing test scripts to identify categories
- Identify obsolete and duplicate scripts
- Map dependencies between scripts

### Phase 2: Directory Structure Creation
- Create new `tests/` directory structure
- Set up subdirectories for each test category
- Create placeholder documentation files

### Phase 3: Script Migration
- Move scripts to appropriate categories
- Update path references within scripts
- Preserve executable permissions

### Phase 4: Master Test Runner
- Implement unified test runner script
- Add category-based execution options
- Integrate reporting functionality

### Phase 5: Documentation and Cleanup
- Create comprehensive README documentation
- Remove obsolete scripts from root directory
- Update any references to moved scripts