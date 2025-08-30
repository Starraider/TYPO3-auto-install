#!/bin/bash

# Debug script to test hyphenated project names specifically

# Source path resolution utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

# Source replacement functions from project root
source_project_file "replacement_functions_only.sh"

# Create test directory
rm -rf tests/fixtures/debug_test
mkdir -p tests/fixtures/debug_test

# Create simple test file
echo "xxxx_sitepackage content" > tests/fixtures/debug_test/test.txt

echo "Testing hyphenated project name..."
echo "Before: $(cat tests/fixtures/debug_test/test.txt)"

# Test the corrected case (sitepackage name must use underscores, not hyphens)
if replace_sitepackage_placeholders "tests/fixtures/debug_test" "my-project" "my_project_sitepackage" "my-project-sitepackage" "MyProjectSitepackage" "my-vendor" "true"; then
    echo "SUCCESS: Function completed"
    echo "After: $(cat tests/fixtures/debug_test/test.txt)"
else
    echo "FAILED: Function returned error code $?"
    echo "Current content: $(cat tests/fixtures/debug_test/test.txt)"
fi

# Cleanup
rm -rf tests/fixtures/debug_test