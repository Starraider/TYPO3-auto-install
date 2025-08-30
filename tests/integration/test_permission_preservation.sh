#!/bin/bash

# Test script for file permission and structure preservation functionality
# This script tests the enhanced replace_sitepackage_placeholders function

set -e

# Source path resolution utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

# Clear any cached paths to ensure fresh resolution
clear_path_cache

# Resolve project paths
PROJECT_ROOT="$(resolve_project_root)"
if [ $? -ne 0 ]; then
    echo "ERROR: Could not locate project root directory"
    exit 1
fi

echo "=== Testing File Permission and Structure Preservation ==="

# Create a test directory structure
TEST_DIR="test_permission_preservation"
rm -rf "$TEST_DIR" 2>/dev/null || true
mkdir -p "$TEST_DIR"

# Create test files with different permissions
echo "Creating test files with various permissions..."

# Regular file with standard permissions
echo "This is a test file with xxxx_sitepackage placeholder" > "$TEST_DIR/regular_file.txt"
chmod 644 "$TEST_DIR/regular_file.txt"

# Executable file
echo "#!/bin/bash
echo 'Script with xxxx placeholder'" > "$TEST_DIR/executable_script.sh"
chmod 755 "$TEST_DIR/executable_script.sh"

# Read-only file
echo "Read-only file with XxxxSitepackage placeholder" > "$TEST_DIR/readonly_file.txt"
chmod 444 "$TEST_DIR/readonly_file.txt"

# Create a symbolic link
echo "Target file with xxxx-sitepackage placeholder" > "$TEST_DIR/target_file.txt"
chmod 664 "$TEST_DIR/target_file.txt"
ln -s "target_file.txt" "$TEST_DIR/symlink_file.txt"

# Create essential TYPO3 directories
mkdir -p "$TEST_DIR/Classes"
mkdir -p "$TEST_DIR/Configuration"
mkdir -p "$TEST_DIR/Resources/Private"
mkdir -p "$TEST_DIR/Resources/Public"

# Add some files in the directories
echo "<?php
class XxxxSitepackage {
    // xxxx_sitepackage class
}" > "$TEST_DIR/Classes/TestClass.php"
chmod 644 "$TEST_DIR/Classes/TestClass.php"

echo "# Configuration with skom vendor
vendor: skom
project: xxxx" > "$TEST_DIR/Configuration/config.yaml"
chmod 644 "$TEST_DIR/Configuration/config.yaml"

# Store original permissions for verification
echo "Storing original permissions..."
ORIGINAL_REGULAR=$(stat -f "%Lp" "$TEST_DIR/regular_file.txt" 2>/dev/null || stat -c "%a" "$TEST_DIR/regular_file.txt" 2>/dev/null)
ORIGINAL_EXECUTABLE=$(stat -f "%Lp" "$TEST_DIR/executable_script.sh" 2>/dev/null || stat -c "%a" "$TEST_DIR/executable_script.sh" 2>/dev/null)
ORIGINAL_READONLY=$(stat -f "%Lp" "$TEST_DIR/readonly_file.txt" 2>/dev/null || stat -c "%a" "$TEST_DIR/readonly_file.txt" 2>/dev/null)
ORIGINAL_TARGET=$(stat -f "%Lp" "$TEST_DIR/target_file.txt" 2>/dev/null || stat -c "%a" "$TEST_DIR/target_file.txt" 2>/dev/null)

echo "Original permissions:"
echo "  Regular file: $ORIGINAL_REGULAR"
echo "  Executable script: $ORIGINAL_EXECUTABLE"
echo "  Read-only file: $ORIGINAL_READONLY"
echo "  Target file: $ORIGINAL_TARGET"

# Source the replacement function from install-typo3.sh
echo "Sourcing replacement function..."
INSTALL_SCRIPT="$PROJECT_ROOT/install-typo3.sh"
if [ -f "$INSTALL_SCRIPT" ]; then
    # Create a temporary file with just the functions we need
    TEMP_FUNCTIONS=$(mktemp)
    
    # Extract all the functions we need
    echo "# Extracted functions for testing" > "$TEMP_FUNCTIONS"
    
    # Extract utility functions first (dependencies)
    sed -n '/^portable_sed()/,/^}$/p' "$INSTALL_SCRIPT" >> "$TEMP_FUNCTIONS"
    echo "" >> "$TEMP_FUNCTIONS"
    
    sed -n '/^check_system_compatibility()/,/^}$/p' "$INSTALL_SCRIPT" >> "$TEMP_FUNCTIONS"
    echo "" >> "$TEMP_FUNCTIONS"
    
    # Extract helper functions
    sed -n '/^get_file_access_status()/,/^}$/p' "$INSTALL_SCRIPT" >> "$TEMP_FUNCTIONS"
    echo "" >> "$TEMP_FUNCTIONS"
    
    sed -n '/^should_process_file_with_reason()/,/^}$/p' "$INSTALL_SCRIPT" >> "$TEMP_FUNCTIONS"
    echo "" >> "$TEMP_FUNCTIONS"
    
    sed -n '/^should_process_file()/,/^}$/p' "$INSTALL_SCRIPT" >> "$TEMP_FUNCTIONS"
    echo "" >> "$TEMP_FUNCTIONS"
    
    sed -n '/^is_text_file()/,/^}$/p' "$INSTALL_SCRIPT" >> "$TEMP_FUNCTIONS"
    echo "" >> "$TEMP_FUNCTIONS"
    
    sed -n '/^find_processable_files()/,/^}$/p' "$INSTALL_SCRIPT" >> "$TEMP_FUNCTIONS"
    echo "" >> "$TEMP_FUNCTIONS"
    
    sed -n '/^process_file_replacements_with_stats()/,/^}$/p' "$INSTALL_SCRIPT" >> "$TEMP_FUNCTIONS"
    echo "" >> "$TEMP_FUNCTIONS"
    
    sed -n '/^verify_directory_structure_integrity()/,/^}$/p' "$INSTALL_SCRIPT" >> "$TEMP_FUNCTIONS"
    echo "" >> "$TEMP_FUNCTIONS"
    
    sed -n '/^perform_post_processing_verification()/,/^}$/p' "$INSTALL_SCRIPT" >> "$TEMP_FUNCTIONS"
    echo "" >> "$TEMP_FUNCTIONS"
    
    sed -n '/^validate_replacement_parameters()/,/^}$/p' "$INSTALL_SCRIPT" >> "$TEMP_FUNCTIONS"
    echo "" >> "$TEMP_FUNCTIONS"
    
    # Extract main replacement function
    sed -n '/^replace_sitepackage_placeholders()/,/^}$/p' "$INSTALL_SCRIPT" >> "$TEMP_FUNCTIONS"
    echo "" >> "$TEMP_FUNCTIONS"
    
    # Source the extracted functions
    source "$TEMP_FUNCTIONS"
    
    # Clean up
    rm -f "$TEMP_FUNCTIONS"
    
    echo "Functions sourced successfully"
else
    echo "ERROR: install-typo3.sh not found at $INSTALL_SCRIPT"
    exit 1
fi

# Test the replacement function
echo "Testing replacement function with verbose output..."
if replace_sitepackage_placeholders "$TEST_DIR" "myproject" "myproject_sitepackage" "myproject-sitepackage" "MyprojectSitepackage" "myvendor" true; then
    echo "✓ Replacement function completed successfully"
else
    echo "✗ Replacement function failed"
    exit 1
fi

# Verify permissions were preserved
echo "Verifying permissions were preserved..."
NEW_REGULAR=$(stat -f "%Lp" "$TEST_DIR/regular_file.txt" 2>/dev/null || stat -c "%a" "$TEST_DIR/regular_file.txt" 2>/dev/null)
NEW_EXECUTABLE=$(stat -f "%Lp" "$TEST_DIR/executable_script.sh" 2>/dev/null || stat -c "%a" "$TEST_DIR/executable_script.sh" 2>/dev/null)
NEW_READONLY=$(stat -f "%Lp" "$TEST_DIR/readonly_file.txt" 2>/dev/null || stat -c "%a" "$TEST_DIR/readonly_file.txt" 2>/dev/null)
NEW_TARGET=$(stat -f "%Lp" "$TEST_DIR/target_file.txt" 2>/dev/null || stat -c "%a" "$TEST_DIR/target_file.txt" 2>/dev/null)

echo "New permissions:"
echo "  Regular file: $NEW_REGULAR"
echo "  Executable script: $NEW_EXECUTABLE"
echo "  Read-only file: $NEW_READONLY"
echo "  Target file: $NEW_TARGET"

# Check if permissions match
PERMISSIONS_OK=true
if [ "$ORIGINAL_REGULAR" != "$NEW_REGULAR" ]; then
    echo "✗ Regular file permissions changed: $ORIGINAL_REGULAR -> $NEW_REGULAR"
    PERMISSIONS_OK=false
fi

if [ "$ORIGINAL_EXECUTABLE" != "$NEW_EXECUTABLE" ]; then
    echo "✗ Executable script permissions changed: $ORIGINAL_EXECUTABLE -> $NEW_EXECUTABLE"
    PERMISSIONS_OK=false
fi

if [ "$ORIGINAL_READONLY" != "$NEW_READONLY" ]; then
    echo "✗ Read-only file permissions changed: $ORIGINAL_READONLY -> $NEW_READONLY"
    PERMISSIONS_OK=false
fi

if [ "$ORIGINAL_TARGET" != "$NEW_TARGET" ]; then
    echo "✗ Target file permissions changed: $ORIGINAL_TARGET -> $NEW_TARGET"
    PERMISSIONS_OK=false
fi

if [ "$PERMISSIONS_OK" = "true" ]; then
    echo "✓ All file permissions preserved correctly"
else
    echo "✗ Some file permissions were not preserved"
fi

# Verify symbolic link integrity
echo "Verifying symbolic link integrity..."
if [ -L "$TEST_DIR/symlink_file.txt" ]; then
    LINK_TARGET=$(readlink "$TEST_DIR/symlink_file.txt")
    if [ "$LINK_TARGET" = "target_file.txt" ]; then
        echo "✓ Symbolic link preserved correctly: $LINK_TARGET"
    else
        echo "✗ Symbolic link target changed: $LINK_TARGET"
    fi
else
    echo "✗ Symbolic link no longer exists or is not a link"
fi

# Verify directory structure
echo "Verifying directory structure integrity..."
STRUCTURE_OK=true
for dir in "Classes" "Configuration" "Resources" "Resources/Private" "Resources/Public"; do
    if [ -d "$TEST_DIR/$dir" ]; then
        echo "✓ Directory exists: $dir"
    else
        echo "✗ Directory missing: $dir"
        STRUCTURE_OK=false
    fi
done

if [ "$STRUCTURE_OK" = "true" ]; then
    echo "✓ Directory structure preserved correctly"
else
    echo "✗ Directory structure was corrupted"
fi

# Verify replacements were made
echo "Verifying placeholder replacements..."
REPLACEMENTS_OK=true

if grep -q "myproject_sitepackage" "$TEST_DIR/regular_file.txt"; then
    echo "✓ xxxx_sitepackage replaced in regular file"
else
    echo "✗ xxxx_sitepackage not replaced in regular file"
    REPLACEMENTS_OK=false
fi

if grep -q "MyprojectSitepackage" "$TEST_DIR/Classes/TestClass.php"; then
    echo "✓ XxxxSitepackage replaced in PHP class"
else
    echo "✗ XxxxSitepackage not replaced in PHP class"
    REPLACEMENTS_OK=false
fi

if grep -q "myvendor" "$TEST_DIR/Configuration/config.yaml"; then
    echo "✓ skom replaced with vendor name"
else
    echo "✗ skom not replaced with vendor name"
    REPLACEMENTS_OK=false
fi

if [ "$REPLACEMENTS_OK" = "true" ]; then
    echo "✓ All placeholder replacements completed correctly"
else
    echo "✗ Some placeholder replacements failed"
fi

# Final summary
echo ""
echo "=== Test Summary ==="
if [ "$PERMISSIONS_OK" = "true" ] && [ "$STRUCTURE_OK" = "true" ] && [ "$REPLACEMENTS_OK" = "true" ]; then
    echo "✓ ALL TESTS PASSED - File permission and structure preservation working correctly"
    FINAL_RESULT=0
else
    echo "✗ SOME TESTS FAILED - Issues detected with permission/structure preservation"
    FINAL_RESULT=1
fi

# Cleanup
echo "Cleaning up test directory..."
rm -rf "$TEST_DIR"

exit $FINAL_RESULT