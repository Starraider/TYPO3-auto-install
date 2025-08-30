#!/bin/bash

# Example Usage of Path Resolution Utilities
# This demonstrates how test scripts should use the path utilities after being moved

# Source the path utilities (adjust path based on your script's location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/path-utils.sh"

# Example 1: Basic path resolution
echo "=== Basic Path Resolution ==="
PROJECT_ROOT="$(resolve_project_root)"
echo "Project root: $PROJECT_ROOT"

SCRIPT_DIR_RESOLVED="$(get_script_directory)"
echo "Script directory: $SCRIPT_DIR_RESOLVED"

# Example 2: Resolving project files
echo ""
echo "=== Resolving Project Files ==="
INSTALL_SCRIPT="$(resolve_project_path "install-typo3.sh")"
echo "Install script: $INSTALL_SCRIPT"

CONFIG_FILE="$(resolve_project_path "install.config")"
echo "Config file: $CONFIG_FILE"

# Example 3: Resolving test-related paths
echo ""
echo "=== Resolving Test Paths ==="
TEST_FIXTURES="$(resolve_tests_path "fixtures")"
echo "Test fixtures directory: $TEST_FIXTURES"

TEST_REPORTS="$(resolve_tests_path "reports")"
echo "Test reports directory: $TEST_REPORTS"

# Example 4: Sourcing project files safely
echo ""
echo "=== Sourcing Project Files ==="
if source_project_file "replacement_functions_only.sh"; then
    echo "✓ Successfully sourced replacement functions"
    # Now you can use functions from the sourced file
    if type validate_replacement_parameters >/dev/null 2>&1; then
        echo "✓ Function validate_replacement_parameters is available"
    fi
else
    echo "✗ Failed to source replacement functions"
fi

# Example 5: Environment validation
echo ""
echo "=== Environment Validation ==="
echo "Validating test environment..."
validate_test_environment

echo "Relative script path: $(get_relative_script_path)"

# Example 6: Debug information
echo ""
echo "=== Debug Information ==="
debug_path_resolution

echo ""
echo "=== Example Complete ==="