#!/bin/bash

# Unit Tests for Individual Replacement Function Components
# This script tests specific helper functions and components in isolation

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

# Test configuration
TEST_DIR="test_units"
INSTALL_SCRIPT="$PROJECT_ROOT/install-typo3.sh"
FUNCTIONS_FILE="$PROJECT_ROOT/replacement_functions_only.sh"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test statistics
UNIT_TESTS_RUN=0
UNIT_TESTS_PASSED=0
UNIT_TESTS_FAILED=0

log_unit_test() {
    echo -e "\n${BLUE}[UNIT TEST]${NC} $1"
    UNIT_TESTS_RUN=$((UNIT_TESTS_RUN + 1))
}

log_unit_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    UNIT_TESTS_PASSED=$((UNIT_TESTS_PASSED + 1))
}

log_unit_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    UNIT_TESTS_FAILED=$((UNIT_TESTS_FAILED + 1))
}

# Setup
setup_unit_tests() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    
    # Extract functions if needed
    if [ ! -f "$FUNCTIONS_FILE" ]; then
        "$PROJECT_ROOT/tests/development/extract_replacement_functions.sh"
    fi
    
    # Source the functions
    source "$FUNCTIONS_FILE"
}

# Test parameter validation function
test_parameter_validation() {
    log_unit_test "Parameter Validation Function"
    
    # Test valid parameters
    local result=$(validate_replacement_parameters "$TEST_DIR" "test" "test_sitepackage" "test-sitepackage" "TestSitepackage" "vendor" "false" "[TEST]")
    if [[ "$result" == "validation_passed" ]]; then
        log_unit_pass "Valid parameters accepted"
    else
        log_unit_fail "Valid parameters rejected: $result"
    fi
    
    # Test invalid parameters (disable exit on error temporarily)
    set +e
    result=$(validate_replacement_parameters "" "" "" "" "" "" "false" "[TEST]" 2>/dev/null)
    set -e
    if [[ "$result" == "validation_failed"* ]]; then
        log_unit_pass "Invalid parameters correctly rejected"
    else
        log_unit_fail "Invalid parameters incorrectly accepted"
    fi
    
    # Test parameter format validation (disable exit on error temporarily)
    set +e
    result=$(validate_replacement_parameters "$TEST_DIR" "test@invalid" "test_sitepackage" "test-sitepackage" "TestSitepackage" "vendor" "false" "[TEST]" 2>/dev/null)
    set -e
    if [[ "$result" == "validation_failed"* ]]; then
        log_unit_pass "Invalid character validation working"
    else
        log_unit_fail "Invalid character validation failed"
    fi
}

# Test file type detection
test_file_type_detection() {
    log_unit_test "File Type Detection"
    
    # Create test files
    echo "text content" > "$TEST_DIR/text.txt"
    echo -e '\x00\x01\x02\x03' > "$TEST_DIR/binary.bin"
    touch "$TEST_DIR/empty.txt"
    
    # Test text file detection
    if is_text_file "$TEST_DIR/text.txt" "false"; then
        log_unit_pass "Text file correctly identified"
    else
        log_unit_fail "Text file incorrectly identified as binary"
    fi
    
    # Test binary file detection
    if ! is_text_file "$TEST_DIR/binary.bin" "false"; then
        log_unit_pass "Binary file correctly identified"
    else
        log_unit_fail "Binary file incorrectly identified as text"
    fi
    
    # Test empty file handling
    if is_text_file "$TEST_DIR/empty.txt" "false"; then
        log_unit_pass "Empty file correctly handled"
    else
        log_unit_fail "Empty file incorrectly handled"
    fi
}

# Test file access status checking
test_file_access_status() {
    log_unit_test "File Access Status Checking"
    
    # Create test files with different permissions
    echo "content" > "$TEST_DIR/normal.txt"
    echo "content" > "$TEST_DIR/readonly.txt"
    chmod 444 "$TEST_DIR/readonly.txt"
    
    # Test normal file
    local status=$(get_file_access_status "$TEST_DIR/normal.txt" "false" "[TEST]")
    if [[ "$status" == "accessible" ]]; then
        log_unit_pass "Normal file access status correct"
    else
        log_unit_fail "Normal file access status incorrect: $status"
    fi
    
    # Test read-only file
    status=$(get_file_access_status "$TEST_DIR/readonly.txt" "false" "[TEST]")
    if [[ "$status" == "read_only" ]]; then
        log_unit_pass "Read-only file access status correct"
    else
        log_unit_fail "Read-only file access status incorrect: $status"
    fi
    
    # Test non-existent file
    status=$(get_file_access_status "$TEST_DIR/nonexistent.txt" "false" "[TEST]")
    if [[ "$status" == "not_found" ]]; then
        log_unit_pass "Non-existent file access status correct"
    else
        log_unit_fail "Non-existent file access status incorrect: $status"
    fi
    
    # Cleanup
    chmod 644 "$TEST_DIR/readonly.txt" 2>/dev/null || true
}

# Test file processing logic
test_file_processing() {
    log_unit_test "File Processing Logic"
    
    # Create test file with all placeholder patterns
    cat > "$TEST_DIR/process_test.php" << 'EOF'
<?php
class Test {
    protected $sitepackage = 'xxxx_sitepackage';
    protected $kebab = 'xxxx-sitepackage';
    protected $pascal = 'XxxxSitepackage';
    protected $vendor = 'skom';
    protected $project = 'xxxx';
    protected $notReplaced = 'xxxxx';
}
EOF
    
    # Test the processing function
    local result=$(process_file_replacements_with_stats "$TEST_DIR/process_test.php" "test_sitepackage" "test-sitepackage" "TestSitepackage" "test" "testvendor" "testvendor" "false" "[TEST]")
    
    if [[ "$result" == "success:"* ]]; then
        local replacement_count="${result#success:}"
        if [ "$replacement_count" -gt 0 ]; then
            log_unit_pass "File processing successful with $replacement_count replacements"
            
            # Verify replacements were made
            if grep -q "test_sitepackage" "$TEST_DIR/process_test.php" && \
               grep -q "test-sitepackage" "$TEST_DIR/process_test.php" && \
               grep -q "TestSitepackage" "$TEST_DIR/process_test.php" && \
               grep -q "testvendor" "$TEST_DIR/process_test.php" && \
               grep -q "test" "$TEST_DIR/process_test.php"; then
                log_unit_pass "All expected replacements found in processed file"
            else
                log_unit_fail "Expected replacements not found in processed file"
            fi
            
            # Verify non-matches were preserved
            if grep -q "xxxxx" "$TEST_DIR/process_test.php"; then
                log_unit_pass "Non-matching patterns correctly preserved"
            else
                log_unit_fail "Non-matching patterns were incorrectly replaced"
            fi
        else
            log_unit_fail "No replacements made in file processing"
        fi
    else
        log_unit_fail "File processing failed: $result"
    fi
}

# Test find processable files function
test_find_processable_files() {
    log_unit_test "Find Processable Files Function"
    
    # Create directory structure with various file types
    mkdir -p "$TEST_DIR/find_test"/{Classes,Resources,node_modules}
    
    # Processable files
    touch "$TEST_DIR/find_test/Classes/Test.php"
    touch "$TEST_DIR/find_test/Resources/config.yaml"
    touch "$TEST_DIR/find_test/README.md"
    
    # Non-processable files
    touch "$TEST_DIR/find_test/image.png"
    touch "$TEST_DIR/find_test/archive.zip"
    touch "$TEST_DIR/find_test/.DS_Store"
    touch "$TEST_DIR/find_test/node_modules/package.json"
    
    # Count found files
    local found_files=$(find_processable_files "$TEST_DIR/find_test" "false" | wc -l)
    
    # Should find 3 processable files (Test.php, config.yaml, README.md)
    # node_modules/package.json should be excluded
    if [ "$found_files" -eq 3 ]; then
        log_unit_pass "Find processable files working correctly ($found_files files found)"
    else
        log_unit_fail "Find processable files incorrect count: $found_files (expected 3)"
    fi
}

# Test placeholder verification function
test_placeholder_verification() {
    log_unit_test "Placeholder Verification Function"
    
    # Create test files with remaining placeholders
    mkdir -p "$TEST_DIR/verify_test"
    echo "This file has xxxx_sitepackage placeholder" > "$TEST_DIR/verify_test/remaining.php"
    echo "This file is clean" > "$TEST_DIR/verify_test/clean.php"
    
    # Test verification with remaining placeholders
    set +e
    find_remaining_placeholders "$TEST_DIR/verify_test" "false" "[TEST]" >/dev/null 2>&1
    local find_result=$?
    set -e
    if [ $find_result -ne 0 ]; then
        log_unit_pass "Placeholder verification correctly detected remaining placeholders"
    else
        log_unit_fail "Placeholder verification failed to detect remaining placeholders"
    fi
    
    # Clean up the remaining placeholder and test again
    sed -i '' 's/xxxx_sitepackage/test_sitepackage/g' "$TEST_DIR/verify_test/remaining.php" 2>/dev/null || \
    sed -i 's/xxxx_sitepackage/test_sitepackage/g' "$TEST_DIR/verify_test/remaining.php" 2>/dev/null
    
    set +e
    find_remaining_placeholders "$TEST_DIR/verify_test" "false" "[TEST]" >/dev/null 2>&1
    local find_result2=$?
    set -e
    if [ $find_result2 -eq 0 ]; then
        log_unit_pass "Placeholder verification correctly passed with no remaining placeholders"
    else
        log_unit_fail "Placeholder verification incorrectly failed with no remaining placeholders"
    fi
}

# Test directory structure verification
test_directory_structure_verification() {
    log_unit_test "Directory Structure Verification"
    
    # Create proper TYPO3 sitepackage structure
    mkdir -p "$TEST_DIR/structure_test"/{Classes,Configuration,Resources/{Private,Public}}
    
    # Test with proper structure
    if verify_directory_structure_integrity "$TEST_DIR/structure_test" "false" "[TEST]"; then
        log_unit_pass "Directory structure verification passed for valid structure"
    else
        log_unit_fail "Directory structure verification failed for valid structure"
    fi
    
    # Test with missing essential directory
    rm -rf "$TEST_DIR/structure_test/Classes"
    
    set +e
    local result=$(verify_directory_structure_integrity "$TEST_DIR/structure_test" "false" "[TEST]" 2>&1)
    local exit_code=$?
    set -e
    
    if [ $exit_code -eq 2 ]; then
        log_unit_pass "Directory structure verification correctly detected missing directory"
    else
        log_unit_fail "Directory structure verification failed to detect missing directory (exit code: $exit_code)"
    fi
}

# Test special character escaping
test_special_character_escaping() {
    log_unit_test "Special Character Escaping"
    
    # Create test file
    echo "xxxx_sitepackage content" > "$TEST_DIR/escape_test.txt"
    
    # Test with project names containing special characters
    local special_chars_tests=(
        "test-project"
        "test_project"
        "test.project"
        "test123"
    )
    
    for test_name in "${special_chars_tests[@]}"; do
        # Reset test file
        echo "xxxx_sitepackage content" > "$TEST_DIR/escape_test.txt"
        
        # Test escaping by running a simple replacement
        local escaped_name=$(printf '%s\n' "$test_name" | sed 's/[[\.*^$()+?{|]/\\&/g')
        
        if sed -i '' "s/xxxx_sitepackage/${escaped_name}_sitepackage/g" "$TEST_DIR/escape_test.txt" 2>/dev/null || \
           sed -i "s/xxxx_sitepackage/${escaped_name}_sitepackage/g" "$TEST_DIR/escape_test.txt" 2>/dev/null; then
            
            if grep -q "${test_name}_sitepackage" "$TEST_DIR/escape_test.txt"; then
                log_unit_pass "Special character escaping worked for: $test_name"
            else
                log_unit_fail "Special character escaping failed for: $test_name"
            fi
        else
            log_unit_fail "Sed command failed for special characters: $test_name"
        fi
    done
}

# Run all unit tests
run_unit_tests() {
    echo -e "${BLUE}=== UNIT TEST SUITE ===${NC}"
    
    setup_unit_tests
    
    test_parameter_validation
    test_file_type_detection
    test_file_access_status
    test_file_processing
    test_find_processable_files
    test_placeholder_verification
    test_directory_structure_verification
    test_special_character_escaping
    
    # Summary
    echo -e "\n${BLUE}=== UNIT TEST SUMMARY ===${NC}"
    echo "Unit tests run: $UNIT_TESTS_RUN"
    echo -e "${GREEN}Unit tests passed: $UNIT_TESTS_PASSED${NC}"
    echo -e "${RED}Unit tests failed: $UNIT_TESTS_FAILED${NC}"
    
    local success_rate=0
    if [ "$UNIT_TESTS_RUN" -gt 0 ]; then
        success_rate=$((UNIT_TESTS_PASSED * 100 / UNIT_TESTS_RUN))
    fi
    echo "Unit test success rate: ${success_rate}%"
    
    # Cleanup
    rm -rf "$TEST_DIR"
    
    if [ "$UNIT_TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}All unit tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some unit tests failed.${NC}"
        return 1
    fi
}

# Script entry point
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ ! -f "$INSTALL_SCRIPT" ]; then
        echo -e "${RED}Install script not found: $INSTALL_SCRIPT${NC}"
        exit 1
    fi
    
    run_unit_tests
fi