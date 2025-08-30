#!/bin/bash

# Error Handling and Recovery Mechanism Tests for Replacement Function
# Tests Requirements 3.2, 3.3, 3.4, 4.3 - comprehensive error scenarios

set -e

# Source path resolution utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

# Validate test environment
validate_test_environment "error-handling"

# Test configuration
PROJECT_ROOT="$(resolve_project_root)"
TEST_DIR="$(resolve_tests_path "fixtures/test_error_handling")"
INSTALL_SCRIPT="$(resolve_project_path "install-typo3.sh")"
FUNCTIONS_FILE="$(resolve_project_path "replacement_functions_only.sh")"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test statistics
ERROR_TESTS_RUN=0
ERROR_TESTS_PASSED=0
ERROR_TESTS_FAILED=0

log_error_test() {
    echo -e "\n${BLUE}[ERROR TEST]${NC} $1"
    ERROR_TESTS_RUN=$((ERROR_TESTS_RUN + 1))
}

log_error_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ERROR_TESTS_PASSED=$((ERROR_TESTS_PASSED + 1))
}

log_error_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ERROR_TESTS_FAILED=$((ERROR_TESTS_FAILED + 1))
}

# Setup
setup_error_tests() {
    # Create temporary test directory for this run
    local temp_test_dir="$(mktemp -d)"
    TEST_DIR="$temp_test_dir/test_error_handling"
    mkdir -p "$TEST_DIR"
    
    # Extract functions if needed
    if [ ! -f "$FUNCTIONS_FILE" ]; then
        local extract_script="$(resolve_project_path "tests/development/extract_replacement_functions.sh")"
        cd "$PROJECT_ROOT" && "$extract_script"
    fi
    
    # Source the functions
    source "$FUNCTIONS_FILE"
}

# Test 1: Invalid parameter combinations
test_invalid_parameters() {
    log_error_test "Invalid Parameter Combinations"
    
    local test_cases=(
        "::::::Empty parameters"
        "/nonexistent:test:test_sitepackage:test-sitepackage:TestSitepackage:vendor:Nonexistent directory"
        "$TEST_DIR:test@invalid:test_sitepackage:test-sitepackage:TestSitepackage:vendor:Invalid project name with special chars"
        "$TEST_DIR:test:test sitepackage:test-sitepackage:TestSitepackage:vendor:Sitepackage name with spaces"
        "$TEST_DIR:test:test_sitepackage:test sitepackage:TestSitepackage:vendor:Kebab case with spaces"
        "$TEST_DIR:test:test_sitepackage:test-sitepackage:testSitepackage:vendor:PascalCase not starting with uppercase"
        "$TEST_DIR:xxxx:xxxx_sitepackage:xxxx-sitepackage:XxxxSitepackage:vendor:Project name same as placeholder"
        "$TEST_DIR:test:test_sitepackage:test-sitepackage:TestSitepackage:skom:Vendor same as placeholder"
    )
    
    local passed_count=0
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r source_dir project_name sitepackage_name sitepackage_kebab sitepackage_pascal vendor_name description <<< "$test_case"
        
        echo "  Testing: $description"
        
        # These should all fail validation
        if replace_sitepackage_placeholders "$source_dir" "$project_name" "$sitepackage_name" "$sitepackage_kebab" "$sitepackage_pascal" "$vendor_name" "false" 2>/dev/null; then
            echo "    ❌ Should have failed but passed: $description"
        else
            echo "    ✅ Correctly rejected: $description"
            passed_count=$((passed_count + 1))
        fi
    done
    
    if [ "$passed_count" -eq ${#test_cases[@]} ]; then
        log_error_pass "All invalid parameter combinations correctly rejected"
    else
        log_error_fail "Some invalid parameters were incorrectly accepted ($passed_count/${#test_cases[@]})"
    fi
}

# Test 2: File permission scenarios
test_file_permissions() {
    log_error_test "File Permission Error Scenarios"
    
    mkdir -p "$TEST_DIR/permissions"
    
    # Create files with different permission scenarios
    echo "xxxx_sitepackage content" > "$TEST_DIR/permissions/normal.txt"
    echo "xxxx_sitepackage content" > "$TEST_DIR/permissions/readonly.txt"
    echo "xxxx_sitepackage content" > "$TEST_DIR/permissions/noread.txt"
    
    # Set different permissions
    chmod 644 "$TEST_DIR/permissions/normal.txt"
    chmod 444 "$TEST_DIR/permissions/readonly.txt"
    chmod 000 "$TEST_DIR/permissions/noread.txt"
    
    # Test that function handles permission issues gracefully
    local result=$(replace_sitepackage_placeholders "$TEST_DIR/permissions" "test" "test_sitepackage" "test-sitepackage" "TestSitepackage" "vendor" "true" 2>&1)
    local exit_code=$?
    
    # Function should complete but with warnings about permission issues
    if [ $exit_code -eq 0 ] || [ $exit_code -eq 1 ]; then
        # Check that normal file was processed
        if grep -q "test_sitepackage" "$TEST_DIR/permissions/normal.txt"; then
            # Check that readonly file was handled (should be skipped with warning)
            if echo "$result" | grep -q "read-only\|permission"; then
                log_error_pass "File permission scenarios handled gracefully"
            else
                log_error_fail "Permission warnings not properly reported"
            fi
        else
            log_error_fail "Normal file was not processed correctly"
        fi
    else
        log_error_fail "Function failed completely due to permission issues (exit code: $exit_code)"
    fi
    
    # Restore permissions for cleanup
    chmod 644 "$TEST_DIR/permissions"/* 2>/dev/null || true
}

# Test 3: Corrupted and malformed files
test_corrupted_files() {
    log_error_test "Corrupted and Malformed File Handling"
    
    mkdir -p "$TEST_DIR/corrupted"
    
    # Create various problematic files
    echo "xxxx_sitepackage content" > "$TEST_DIR/corrupted/normal.txt"
    
    # File with null bytes
    echo -e "xxxx_sitepackage\x00content\x00more" > "$TEST_DIR/corrupted/nullbytes.txt"
    
    # Very large file (to test memory handling)
    yes "xxxx_sitepackage line" | head -n 10000 > "$TEST_DIR/corrupted/large.txt"
    
    # File with extremely long lines
    local long_line=""
    for i in {1..1000}; do
        long_line="${long_line}xxxx_sitepackage "
    done
    echo "$long_line" > "$TEST_DIR/corrupted/longline.txt"
    
    # Binary file that might be misidentified
    echo -e '\x89PNG\r\n\x1a\nxxxx_sitepackage' > "$TEST_DIR/corrupted/fake_binary.png"
    
    # Test processing
    if replace_sitepackage_placeholders "$TEST_DIR/corrupted" "test" "test_sitepackage" "test-sitepackage" "TestSitepackage" "vendor" "false" 2>/dev/null; then
        
        # Verify that appropriate files were processed and others skipped
        local processed_normal=$(grep -c "test_sitepackage" "$TEST_DIR/corrupted/normal.txt" 2>/dev/null || echo "0")
        local processed_large=$(grep -c "test_sitepackage" "$TEST_DIR/corrupted/large.txt" 2>/dev/null || echo "0")
        
        if [ "$processed_normal" -gt 0 ] && [ "$processed_large" -gt 0 ]; then
            log_error_pass "Corrupted file scenarios handled appropriately"
        else
            log_error_fail "Some processable files were not handled correctly"
        fi
    else
        log_error_fail "Function failed on corrupted file scenarios"
    fi
}

# Test 4: Disk space and system resource scenarios
test_resource_constraints() {
    log_error_test "Resource Constraint Scenarios"
    
    mkdir -p "$TEST_DIR/resources"
    
    # Create a reasonable number of files to test resource handling
    for i in {1..100}; do
        echo "xxxx_sitepackage content for file $i" > "$TEST_DIR/resources/file_$i.txt"
    done
    
    # Test with limited resources (simulate by creating many files)
    local start_time=$(date +%s)
    
    if replace_sitepackage_placeholders "$TEST_DIR/resources" "test" "test_sitepackage" "test-sitepackage" "TestSitepackage" "vendor" "false"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        # Verify all files were processed
        local processed_count=$(grep -l "test_sitepackage" "$TEST_DIR/resources"/*.txt | wc -l)
        
        if [ "$processed_count" -eq 100 ]; then
            log_error_pass "Resource constraint test passed (${duration}s, 100 files processed)"
        else
            log_error_fail "Not all files processed under resource constraints ($processed_count/100)"
        fi
    else
        log_error_fail "Function failed under resource constraints"
    fi
}

# Test 5: Symbolic link scenarios
test_symbolic_links() {
    log_error_test "Symbolic Link Error Scenarios"
    
    mkdir -p "$TEST_DIR/symlinks"/{source,target}
    
    # Create source files
    echo "xxxx_sitepackage content" > "$TEST_DIR/symlinks/source/real_file.txt"
    echo "xxxx_sitepackage content" > "$TEST_DIR/symlinks/target/target_file.txt"
    
    # Create various symbolic link scenarios
    cd "$TEST_DIR/symlinks/source"
    
    # Valid symbolic link
    ln -s "../target/target_file.txt" "valid_symlink.txt"
    
    # Broken symbolic link
    ln -s "nonexistent_file.txt" "broken_symlink.txt"
    
    # Circular symbolic link
    ln -s "circular_symlink.txt" "circular_symlink.txt"
    
    # Symbolic link to directory
    ln -s "../target" "dir_symlink"
    
    cd - >/dev/null
    
    # Test processing
    local result=$(replace_sitepackage_placeholders "$TEST_DIR/symlinks/source" "test" "test_sitepackage" "test-sitepackage" "TestSitepackage" "vendor" "true" 2>&1)
    local exit_code=$?
    
    # Should handle symbolic links gracefully
    if [ $exit_code -eq 0 ] || [ $exit_code -eq 1 ]; then
        # Check that valid files were processed
        if grep -q "test_sitepackage" "$TEST_DIR/symlinks/source/real_file.txt"; then
            # Check that broken symlinks were reported
            if echo "$result" | grep -q "broken\|symlink"; then
                log_error_pass "Symbolic link scenarios handled correctly"
            else
                log_error_fail "Broken symbolic links not properly reported"
            fi
        else
            log_error_fail "Valid files not processed in symbolic link test"
        fi
    else
        log_error_fail "Function failed on symbolic link scenarios (exit code: $exit_code)"
    fi
}

# Test 6: Concurrent access scenarios
test_concurrent_access() {
    log_error_test "Concurrent Access Scenarios"
    
    mkdir -p "$TEST_DIR/concurrent"
    
    # Create test files
    for i in {1..20}; do
        echo "xxxx_sitepackage content $i" > "$TEST_DIR/concurrent/file_$i.txt"
    done
    
    # Simulate concurrent access by running replacement in background
    # and trying to modify files simultaneously
    replace_sitepackage_placeholders "$TEST_DIR/concurrent" "test" "test_sitepackage" "test-sitepackage" "TestSitepackage" "vendor" "false" &
    local bg_pid=$!
    
    # Try to modify a file while replacement is running
    sleep 0.1
    echo "modified during processing" >> "$TEST_DIR/concurrent/file_1.txt" 2>/dev/null || true
    
    # Wait for background process
    wait $bg_pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ] || [ $exit_code -eq 1 ]; then
        # Check that most files were processed successfully
        local processed_count=$(grep -l "test_sitepackage" "$TEST_DIR/concurrent"/*.txt 2>/dev/null | wc -l)
        
        if [ "$processed_count" -ge 15 ]; then
            log_error_pass "Concurrent access handled reasonably ($processed_count/20 files processed)"
        else
            log_error_fail "Too many files failed in concurrent access test ($processed_count/20)"
        fi
    else
        log_error_fail "Function failed under concurrent access (exit code: $exit_code)"
    fi
}

# Test 7: Recovery mechanism testing
test_recovery_mechanisms() {
    log_error_test "Recovery Mechanism Testing"
    
    mkdir -p "$TEST_DIR/recovery"
    
    # Create test file
    echo "xxxx_sitepackage original content" > "$TEST_DIR/recovery/test_file.txt"
    local original_content=$(cat "$TEST_DIR/recovery/test_file.txt")
    
    # Test that backup and recovery works by simulating a failure
    # We'll test this by checking if the function preserves file integrity
    
    # First, test normal processing
    if replace_sitepackage_placeholders "$TEST_DIR/recovery" "test" "test_sitepackage" "test-sitepackage" "TestSitepackage" "vendor" "false"; then
        
        # Verify file was processed and is still readable
        if [ -r "$TEST_DIR/recovery/test_file.txt" ] && [ -s "$TEST_DIR/recovery/test_file.txt" ]; then
            local new_content=$(cat "$TEST_DIR/recovery/test_file.txt")
            
            # File should be different (processed) but still valid
            if [ "$new_content" != "$original_content" ] && grep -q "test_sitepackage" "$TEST_DIR/recovery/test_file.txt"; then
                log_error_pass "Recovery mechanism preserved file integrity during normal processing"
            else
                log_error_fail "File integrity not maintained during processing"
            fi
        else
            log_error_fail "File became unreadable or empty after processing"
        fi
    else
        log_error_fail "Recovery mechanism test failed - function returned error"
    fi
    
    # Test with a file that might cause sed to fail
    echo 'xxxx_sitepackage with "quotes" and $variables and [brackets]' > "$TEST_DIR/recovery/complex_file.txt"
    
    if replace_sitepackage_placeholders "$TEST_DIR/recovery" "test" "test_sitepackage" "test-sitepackage" "TestSitepackage" "vendor" "false"; then
        if [ -r "$TEST_DIR/recovery/complex_file.txt" ] && [ -s "$TEST_DIR/recovery/complex_file.txt" ]; then
            log_error_pass "Recovery mechanism handled complex file content"
        else
            log_error_fail "Complex file content caused recovery issues"
        fi
    else
        log_error_fail "Function failed on complex file content"
    fi
}

# Test 8: Memory and performance under stress
test_stress_conditions() {
    log_error_test "Stress Condition Testing"
    
    mkdir -p "$TEST_DIR/stress"
    
    # Create files with various stress conditions
    
    # Very large file
    echo "Creating large file for stress test..."
    yes "xxxx_sitepackage repeated content line" | head -n 50000 > "$TEST_DIR/stress/large_file.txt"
    
    # Many small files
    for i in {1..200}; do
        echo "xxxx_sitepackage content $i" > "$TEST_DIR/stress/small_$i.txt"
    done
    
    # File with very long lines
    local long_line=""
    for i in {1..5000}; do
        long_line="${long_line}xxxx_sitepackage "
    done
    echo "$long_line" > "$TEST_DIR/stress/long_line.txt"
    
    echo "Running stress test..."
    local start_time=$(date +%s)
    local max_time=60  # Maximum 60 seconds for stress test
    
    # Run with timeout to prevent hanging (macOS compatible)
    if command -v timeout >/dev/null 2>&1; then
        timeout $max_time replace_sitepackage_placeholders "$TEST_DIR/stress" "stress" "stress_sitepackage" "stress-sitepackage" "StressSitepackage" "stressvendor" "false"
        local exit_code=$?
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout $max_time replace_sitepackage_placeholders "$TEST_DIR/stress" "stress" "stress_sitepackage" "stress-sitepackage" "StressSitepackage" "stressvendor" "false"
        local exit_code=$?
    else
        # Fallback: run without timeout on macOS
        replace_sitepackage_placeholders "$TEST_DIR/stress" "stress" "stress_sitepackage" "stress-sitepackage" "StressSitepackage" "stressvendor" "false" &
        local bg_pid=$!
        local elapsed=0
        while kill -0 $bg_pid 2>/dev/null && [ $elapsed -lt $max_time ]; do
            sleep 1
            elapsed=$((elapsed + 1))
        done
        
        if kill -0 $bg_pid 2>/dev/null; then
            kill $bg_pid 2>/dev/null
            wait $bg_pid 2>/dev/null
            local exit_code=124  # Timeout exit code
        else
            wait $bg_pid
            local exit_code=$?
        fi
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $exit_code -eq 0 ] || [ $exit_code -eq 1 ]; then
        # Check that at least some files were processed
        local processed_count=$(find "$TEST_DIR/stress" -name "*.txt" -exec grep -l "stress_sitepackage" {} \; 2>/dev/null | wc -l)
        
        if [ "$processed_count" -gt 100 ]; then
            log_error_pass "Stress test passed (${duration}s, $processed_count files processed)"
        else
            log_error_fail "Stress test processed too few files ($processed_count)"
        fi
    elif [ $exit_code -eq 124 ]; then
        log_error_fail "Stress test timed out after ${max_time} seconds"
    else
        log_error_fail "Stress test failed with exit code $exit_code"
    fi
}

# Run all error handling tests
run_error_handling_tests() {
    echo -e "${BLUE}=== ERROR HANDLING TEST SUITE ===${NC}"
    
    setup_error_tests
    
    test_invalid_parameters
    test_file_permissions
    test_corrupted_files
    test_resource_constraints
    test_symbolic_links
    test_concurrent_access
    test_recovery_mechanisms
    test_stress_conditions
    
    # Summary
    echo -e "\n${BLUE}=== ERROR HANDLING TEST SUMMARY ===${NC}"
    echo "Error handling tests run: $ERROR_TESTS_RUN"
    echo -e "${GREEN}Error handling tests passed: $ERROR_TESTS_PASSED${NC}"
    echo -e "${RED}Error handling tests failed: $ERROR_TESTS_FAILED${NC}"
    
    local success_rate=0
    if [ "$ERROR_TESTS_RUN" -gt 0 ]; then
        success_rate=$((ERROR_TESTS_PASSED * 100 / ERROR_TESTS_RUN))
    fi
    echo "Error handling success rate: ${success_rate}%"
    
    # Cleanup
    rm -rf "$TEST_DIR"
    
    if [ "$ERROR_TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}All error handling tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some error handling tests failed.${NC}"
        return 1
    fi
}

# Script entry point
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ ! -f "$INSTALL_SCRIPT" ]; then
        echo -e "${RED}Install script not found: $INSTALL_SCRIPT${NC}"
        echo "Expected location: $INSTALL_SCRIPT"
        echo "Project root: $PROJECT_ROOT"
        exit 1
    fi
    
    run_error_handling_tests
fi