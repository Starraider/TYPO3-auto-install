#!/bin/bash

# Test Script for Reporting System Validation
# Tests the standardized test result format and reporting functions
# Requirements: 5.3, 5.4

set -e

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/path-utils.sh"
source "$SCRIPT_DIR/lib/test-reporting.sh"

# Clear any cached paths to ensure fresh resolution
clear_path_cache

# Resolve project paths
PROJECT_ROOT="$(resolve_project_root)"
if [ $? -ne 0 ]; then
    echo "ERROR: Could not locate project root directory"
    exit 1
fi

TESTS_DIR="$(resolve_project_path "tests")"
REPORTS_DIR="$(resolve_project_path "tests/reports")"

# Test configuration
TEST_SESSION_ID="test_$(date +%Y%m%d_%H%M%S)"
TEST_REPORTS_DIR="$REPORTS_DIR/test_validation"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Test helper function
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    log_test "Running: $test_name"
    
    if $test_function; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name"
        return 1
    fi
}

# Test 1: Initialize reporting system
test_init_reporting() {
    mkdir -p "$TEST_REPORTS_DIR"
    
    if init_test_reporting "$TEST_REPORTS_DIR" "$TEST_SESSION_ID"; then
        # Check if global variables are set
        if [ -n "$TEST_REPORT_DIR" ] && [ -n "$TEST_SESSION_ID" ] && [ -n "$TEST_START_TIME" ]; then
            return 0
        fi
    fi
    return 1
}

# Test 2: Record test results
test_record_results() {
    # Record various test results
    record_test_result "sample_test_1" "unit" "$TEST_STATUS_PASS" "5" "tests/unit/sample.sh" "0" "Test output" "" "1000" "1005"
    record_test_result "sample_test_2" "integration" "$TEST_STATUS_FAIL" "10" "tests/integration/sample.sh" "1" "Error output" "Test failed" "1010" "1020"
    record_test_result "sample_test_3" "unit" "$TEST_STATUS_SKIP" "0" "tests/unit/skipped.sh" "0" "" "" "1020" "1020"
    
    # Check if results were recorded
    if [ ${#TEST_RESULTS[@]} -eq 3 ]; then
        return 0
    fi
    return 1
}

# Test 3: Parse test results
test_parse_results() {
    local result_data="${TEST_RESULTS[0]}"
    
    local test_name=$(parse_test_result "$result_data" "test_name")
    local category=$(parse_test_result "$result_data" "category")
    local status=$(parse_test_result "$result_data" "status")
    local duration=$(parse_test_result "$result_data" "duration")
    
    if [ "$test_name" = "sample_test_1" ] && [ "$category" = "unit" ] && [ "$status" = "$TEST_STATUS_PASS" ] && [ "$duration" = "5" ]; then
        return 0
    fi
    return 1
}

# Test 4: Calculate statistics
test_calculate_statistics() {
    local stats=$(calculate_test_statistics)
    local total_tests=$(echo "$stats" | cut -d'|' -f1)
    local passed_tests=$(echo "$stats" | cut -d'|' -f2)
    local failed_tests=$(echo "$stats" | cut -d'|' -f3)
    local skipped_tests=$(echo "$stats" | cut -d'|' -f4)
    
    if [ "$total_tests" = "3" ] && [ "$passed_tests" = "1" ] && [ "$failed_tests" = "1" ] && [ "$skipped_tests" = "1" ]; then
        return 0
    fi
    return 1
}

# Test 5: Generate text report
test_generate_text_report() {
    local test_report_file="$TEST_REPORTS_DIR/test_text_report.txt"
    
    if generate_text_report "$test_report_file" "Test Validation Report"; then
        # Check if file was created and contains expected content
        if [ -f "$test_report_file" ] && grep -q "Test Validation Report" "$test_report_file" && grep -q "Total Tests: 3" "$test_report_file"; then
            return 0
        fi
    fi
    return 1
}

# Test 6: Generate JSON report
test_generate_json_report() {
    local test_json_file="$TEST_REPORTS_DIR/test_json_report.json"
    
    if generate_json_report "$test_json_file"; then
        # Check if file was created and contains valid JSON structure
        if [ -f "$test_json_file" ] && grep -q '"total_tests": 3' "$test_json_file" && grep -q '"metadata"' "$test_json_file"; then
            return 0
        fi
    fi
    return 1
}

# Test 7: Generate summary report
test_generate_summary_report() {
    local test_summary_file="$TEST_REPORTS_DIR/test_summary_report.txt"
    local input_report="$TEST_REPORTS_DIR/test_text_report.txt"
    
    if [ -f "$input_report" ]; then
        if generate_summary_report "$test_summary_file" "$input_report"; then
            # Check if summary file was created
            if [ -f "$test_summary_file" ] && grep -q "Summary Report" "$test_summary_file"; then
                return 0
            fi
        fi
    fi
    return 1
}

# Test 8: Test error handling
test_error_handling() {
    # Test invalid status
    if record_test_result "invalid_test" "unit" "INVALID_STATUS" "5" "test.sh" "0" "" "" "1000" "1005" 2>/dev/null; then
        return 1  # Should have failed
    fi
    
    # Test missing required parameters
    if record_test_result "" "" "" "" "" "" "" "" "" "" 2>/dev/null; then
        return 1  # Should have failed
    fi
    
    return 0  # Both tests should have failed as expected
}

# Test 9: Test master runner integration
test_master_runner_integration() {
    # Test that the master runner can use the new reporting system
    local test_output
    test_output=$("$TESTS_DIR/run-tests.sh" --help 2>&1)
    
    if echo "$test_output" | grep -q "Generate test report in JSON format" && echo "$test_output" | grep -q "Generate summary report"; then
        return 0
    fi
    return 1
}

# Test 10: Test report generation utility
test_report_generation_utility() {
    # Test that the report generation utility works
    local test_output
    test_output=$("$TESTS_DIR/generate-report.sh" --help 2>&1)
    
    if echo "$test_output" | grep -q "Generate various types of test reports" && echo "$test_output" | grep -q "summary, analysis, trends"; then
        return 0
    fi
    return 1
}

# Main test execution
main() {
    echo -e "${BOLD}${CYAN}TYPO3 Auto-Install Test Reporting System Validation${NC}"
    echo -e "${BOLD}${CYAN}====================================================${NC}"
    echo
    
    log_info "Starting test reporting system validation..."
    log_info "Test session ID: $TEST_SESSION_ID"
    log_info "Test reports directory: $TEST_REPORTS_DIR"
    echo
    
    # Run all tests
    run_test "Initialize reporting system" test_init_reporting
    run_test "Record test results" test_record_results
    run_test "Parse test results" test_parse_results
    run_test "Calculate statistics" test_calculate_statistics
    run_test "Generate text report" test_generate_text_report
    run_test "Generate JSON report" test_generate_json_report
    run_test "Generate summary report" test_generate_summary_report
    run_test "Error handling" test_error_handling
    run_test "Master runner integration" test_master_runner_integration
    run_test "Report generation utility" test_report_generation_utility
    
    echo
    echo -e "${BOLD}${CYAN}Test Results Summary${NC}"
    echo -e "${BOLD}${CYAN}===================${NC}"
    echo -e "${BOLD}Total Tests:${NC} $TESTS_RUN"
    echo -e "${BOLD}Passed:${NC} ${GREEN}$TESTS_PASSED${NC}"
    echo -e "${BOLD}Failed:${NC} ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}${BOLD}All tests passed! Test reporting system is working correctly.${NC}"
        
        # Show generated test files
        echo
        log_info "Generated test files:"
        if [ -d "$TEST_REPORTS_DIR" ]; then
            ls -la "$TEST_REPORTS_DIR"
        fi
        
        return 0
    else
        echo -e "${RED}${BOLD}Some tests failed. Please review the test reporting system.${NC}"
        return 1
    fi
}

# Run main function
main "$@"