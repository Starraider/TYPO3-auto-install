#!/bin/bash

# Debug validation function specifically

# Source path resolution utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

# Source replacement functions from project root
source_project_file "replacement_functions_only.sh"

echo "Testing validation function directly..."

# Create the test directory first
mkdir -p tests/fixtures/debug_test

# Test the validation function
result=$(validate_replacement_parameters "tests/fixtures/debug_test" "my-project" "my_project_sitepackage" "my-project-sitepackage" "MyProjectSitepackage" "my-vendor" "false" "[TEST]")
exit_code=$?

echo "Validation result: '$result'"
echo "Exit code: $exit_code"

# Parse the result like the main function does
validation_status="${result%%
*}"
echo "Parsed status: '$validation_status'"

if [ "$validation_status" = "validation_passed" ]; then
    echo "✅ Validation should pass"
else
    echo "❌ Validation should fail"
    echo "Full result:"
    echo "$result"
fi