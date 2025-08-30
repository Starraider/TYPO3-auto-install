#!/bin/bash

# Test Script for Path Resolution Utilities
# Tests path resolution across different execution contexts and scenarios

set -e

# Source the path utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/path-utils.sh"

# Test configuration
TEST_RESULTS=()
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_test() {
    echo -e "\n${BLUE}[TEST]${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TEST_RESULTS+=("PASS: $1")
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TEST_RESULTS+=("FAIL: $1")
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Test: Basic project root resolution
test_project_root_resolution() {
    log_test "Project root resolution from tests/lib directory"
    
    local project_root
    project_root="$(resolve_project_root)"
    local exit_code=$?
    
    if [ $exit_code -eq 0 ] && [ -n "$project_root" ]; then
        # Verify the resolved path contains expected project files
        if [ -f "$project_root/install-typo3.sh" ] && \
           [ -f "$project_root/create-sitepackage.sh" ] && \
           [ -f "$project_root/install.config" ]; then
            log_pass "Project root correctly resolved to: $project_root"
        else
            log_fail "Project root resolved but missing expected files: $project_root"
        fi
    else
        log_fail "Failed to resolve project root (exit code: $exit_code)"
    fi
}

# Test: Script directory resolution
test_script_directory_resolution() {
    log_test "Script directory resolution"
    
    local script_dir
    script_dir="$(get_script_directory)"
    local exit_code=$?
    
    if [ $exit_code -eq 0 ] && [ -n "$script_dir" ]; then
        # Verify the script directory is correct
        local expected_dir="$SCRIPT_DIR"
        if [ "$script_dir" = "$expected_dir" ]; then
            log_pass "Script directory correctly resolved to: $script_dir"
        else
            log_fail "Script directory mismatch. Expected: $expected_dir, Got: $script_dir"
        fi
    else
        log_fail "Failed to resolve script directory (exit code: $exit_code)"
    fi
}

# Test: Project path resolution
test_project_path_resolution() {
    log_test "Project path resolution for relative paths"
    
    # Test resolving a known file
    local resolved_path
    resolved_path="$(resolve_project_path "install-typo3.sh")"
    local exit_code=$?
    
    if [ $exit_code -eq 0 ] && [ -f "$resolved_path" ]; then
        log_pass "Project path correctly resolved: install-typo3.sh -> $resolved_path"
    else
        log_fail "Failed to resolve project path for install-typo3.sh (exit code: $exit_code)"
    fi
    
    # Test resolving a directory
    resolved_path="$(resolve_project_path "install-src")"
    exit_code=$?
    
    if [ $exit_code -eq 0 ] && [ -d "$resolved_path" ]; then
        log_pass "Project directory correctly resolved: install-src -> $resolved_path"
    else
        log_fail "Failed to resolve project directory for install-src (exit code: $exit_code)"
    fi
}

# Test: Tests path resolution
test_tests_path_resolution() {
    log_test "Tests path resolution for relative paths"
    
    local resolved_path
    resolved_path="$(resolve_tests_path "lib/path-utils.sh")"
    local exit_code=$?
    
    if [ $exit_code -eq 0 ] && [ -f "$resolved_path" ]; then
        log_pass "Tests path correctly resolved: lib/path-utils.sh -> $resolved_path"
    else
        log_fail "Failed to resolve tests path for lib/path-utils.sh (exit code: $exit_code)"
    fi
}

# Test: Source project file functionality
test_source_project_file() {
    log_test "Source project file functionality"
    
    # Create a temporary test file in the project root
    local project_root
    project_root="$(resolve_project_root)"
    local test_file="$project_root/test_source_temp.sh"
    
    # Create test file with a function
    cat > "$test_file" << 'EOF'
#!/bin/bash
test_sourced_function() {
    echo "test_function_executed"
}
EOF
    
    # Test sourcing the file
    if source_project_file "test_source_temp.sh"; then
        # Check if the function was sourced
        if type test_sourced_function >/dev/null 2>&1; then
            local result
            result="$(test_sourced_function)"
            if [ "$result" = "test_function_executed" ]; then
                log_pass "Project file successfully sourced and function available"
            else
                log_fail "Project file sourced but function returned unexpected result: $result"
            fi
        else
            log_fail "Project file sourced but function not available"
        fi
    else
        log_fail "Failed to source project file"
    fi
    
    # Cleanup
    rm -f "$test_file"
}

# Test: Test environment validation
test_environment_validation() {
    log_test "Test environment validation"
    
    # This should pass since we're in tests/lib
    if validate_test_environment 2>/dev/null; then
        log_pass "Test environment validation passed"
    else
        log_fail "Test environment validation failed"
    fi
    
    # Test with specific category (should show warning since we're not in a category dir)
    local output
    output="$(validate_test_environment "unit" 2>&1)"
    if echo "$output" | grep -q "WARNING.*category"; then
        log_pass "Category validation correctly shows warning for wrong directory"
    else
        log_fail "Category validation did not show expected warning"
    fi
}

# Test: Relative script path calculation
test_relative_script_path() {
    log_test "Relative script path calculation"
    
    local relative_path
    relative_path="$(get_relative_script_path)"
    local exit_code=$?
    
    if [ $exit_code -eq 0 ] && [ -n "$relative_path" ]; then
        # Should be something like "tests/lib"
        if [[ "$relative_path" == *"tests/lib"* ]] || [ "$relative_path" = "tests/lib" ]; then
            log_pass "Relative script path correctly calculated: $relative_path"
        else
            log_fail "Relative script path unexpected: $relative_path"
        fi
    else
        log_fail "Failed to calculate relative script path (exit code: $exit_code)"
    fi
}

# Test: Path caching functionality
test_path_caching() {
    log_test "Path caching functionality"
    
    # Clear cache first
    clear_path_cache
    
    # First call should populate cache
    local first_call
    first_call="$(resolve_project_root)"
    
    # Second call should use cache (we can't easily test this directly, but ensure it works)
    local second_call
    second_call="$(resolve_project_root)"
    
    if [ "$first_call" = "$second_call" ] && [ -n "$first_call" ]; then
        log_pass "Path caching working correctly"
    else
        log_fail "Path caching inconsistent results"
    fi
    
    # Test cache clearing
    clear_path_cache
    local after_clear
    after_clear="$(resolve_project_root)"
    
    if [ "$after_clear" = "$first_call" ]; then
        log_pass "Cache clearing and re-resolution working"
    else
        log_fail "Cache clearing or re-resolution failed"
    fi
}

# Test: Error handling for invalid paths
test_error_handling() {
    log_test "Error handling for invalid scenarios"
    
    # Test resolving empty project path
    if ! resolve_project_path "" >/dev/null 2>&1; then
        log_pass "Error handling for empty path works correctly"
    else
        log_fail "Error handling for empty path not working - should have failed"
    fi
    
    # Test sourcing non-existent file
    if ! source_project_file "non_existent_file_12345.sh" >/dev/null 2>&1; then
        log_pass "Error handling for non-existent file works correctly"
    else
        log_fail "Error handling for non-existent file not working - should have failed"
    fi
    
    # Test resolve_tests_path with empty input
    if ! resolve_tests_path "" >/dev/null 2>&1; then
        log_pass "Error handling for empty tests path works correctly"
    else
        log_fail "Error handling for empty tests path not working - should have failed"
    fi
}

# Test: Cross-platform compatibility
test_cross_platform_compatibility() {
    log_test "Cross-platform compatibility"
    
    # Test that path resolution works regardless of platform
    local project_root
    project_root="$(resolve_project_root)"
    
    # Check that the path doesn't contain backslashes (Windows-style)
    if [[ "$project_root" != *"\\"* ]]; then
        log_pass "Path resolution uses Unix-style paths"
    else
        log_fail "Path resolution contains Windows-style backslashes"
    fi
    
    # Test that the path is absolute
    if [[ "$project_root" == /* ]]; then
        log_pass "Project root is absolute path"
    else
        log_fail "Project root is not absolute path: $project_root"
    fi
}

# Test execution from different directories
test_execution_contexts() {
    log_test "Execution from different directories"
    
    # Save current directory
    local original_dir="$(pwd)"
    
    # Test from project root
    local project_root
    project_root="$(resolve_project_root)"
    cd "$project_root"
    
    local root_result
    root_result="$(bash -c 'source tests/lib/path-utils.sh; resolve_project_root')"
    
    if [ "$root_result" = "$project_root" ]; then
        log_pass "Path resolution works from project root"
    else
        log_fail "Path resolution failed from project root: $root_result"
    fi
    
    # Test from a subdirectory
    if [ -d "$project_root/install-src" ]; then
        cd "$project_root/install-src"
        local subdir_result
        subdir_result="$(bash -c 'source ../tests/lib/path-utils.sh; resolve_project_root')"
        
        if [ "$subdir_result" = "$project_root" ]; then
            log_pass "Path resolution works from subdirectory"
        else
            log_fail "Path resolution failed from subdirectory: $subdir_result"
        fi
    fi
    
    # Restore original directory
    cd "$original_dir"
}

# Main test runner
run_all_tests() {
    echo -e "${BLUE}=== PATH UTILITIES TEST SUITE ===${NC}"
    echo "Testing path resolution utilities across different execution contexts"
    echo ""
    
    # Run all tests
    test_project_root_resolution
    test_script_directory_resolution
    test_project_path_resolution
    test_tests_path_resolution
    test_source_project_file
    test_environment_validation
    test_relative_script_path
    test_path_caching
    test_error_handling
    test_cross_platform_compatibility
    test_execution_contexts
    
    # Display summary
    echo ""
    echo -e "${BLUE}=== TEST SUMMARY ===${NC}"
    echo "Tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    
    if [ "$TESTS_RUN" -gt 0 ]; then
        local success_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
        echo "Success rate: ${success_rate}%"
    fi
    
    # Show detailed results if there were failures
    if [ "$TESTS_FAILED" -gt 0 ]; then
        echo ""
        echo -e "${RED}Failed tests:${NC}"
        for result in "${TEST_RESULTS[@]}"; do
            if [[ "$result" == "FAIL:"* ]]; then
                echo "  - ${result#FAIL: }"
            fi
        done
    fi
    
    echo ""
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}All path utility tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some path utility tests failed.${NC}"
        return 1
    fi
}

# Script entry point
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    run_all_tests
fi