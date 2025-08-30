#!/bin/bash

# Master Test Runner Script
# Provides unified interface for executing all test categories in the TYPO3 auto-install project
# Requirements: 5.1, 5.2, 5.3

set -e

# Source path resolution utilities and test reporting
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

# Ensure reports directory exists
mkdir -p "$REPORTS_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test categories and their corresponding scripts (bash 3.2 compatible)
get_category_scripts() {
    local category="$1"
    case "$category" in
        unit)
            echo "tests/unit/test_replacement_units.sh tests/unit/test_simple_permissions.sh"
            ;;
        integration)
            echo "tests/integration/test_real_sitepackage.sh tests/integration/test_permission_preservation.sh"
            ;;
        compatibility)
            echo "tests/compatibility/run_all_compatibility_tests.sh"
            ;;
        error-handling)
            echo "tests/error-handling/test_replacement_error_handling.sh"
            ;;
        development)
            echo "tests/development/debug_validation.sh tests/development/test_replacement_quick.sh"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Available test categories
ALL_CATEGORIES="unit integration compatibility error-handling development"

# Global test statistics
TOTAL_TESTS_RUN=0
TOTAL_TESTS_PASSED=0
TOTAL_TESTS_FAILED=0
TOTAL_CATEGORIES_RUN=0
FAILED_TESTS=()

# Configuration variables
VERBOSE=false
GENERATE_REPORT=false
GENERATE_JSON=false
GENERATE_SUMMARY=false
CATEGORY=""
LIST_CATEGORIES=false
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPORTS_DIR/test_run_report_$TIMESTAMP.txt"
JSON_REPORT_FILE="$REPORTS_DIR/test_run_report_$TIMESTAMP.json"
SUMMARY_REPORT_FILE="$REPORTS_DIR/test_summary_$TIMESTAMP.txt"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    if [ "$GENERATE_REPORT" = true ]; then
        echo "[INFO] $1" >> "$REPORT_FILE"
    fi
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    if [ "$GENERATE_REPORT" = true ]; then
        echo "[PASS] $1" >> "$REPORT_FILE"
    fi
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    if [ "$GENERATE_REPORT" = true ]; then
        echo "[WARN] $1" >> "$REPORT_FILE"
    fi
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    if [ "$GENERATE_REPORT" = true ]; then
        echo "[FAIL] $1" >> "$REPORT_FILE"
    fi
}

log_header() {
    echo -e "${CYAN}${BOLD}=== $1 ===${NC}"
    if [ "$GENERATE_REPORT" = true ]; then
        echo "=== $1 ===" >> "$REPORT_FILE"
    fi
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${YELLOW}[VERBOSE]${NC} $1"
        if [ "$GENERATE_REPORT" = true ]; then
            echo "[VERBOSE] $1" >> "$REPORT_FILE"
        fi
    fi
}

# Function to display usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Master test runner for TYPO3 auto-install project test suite.

OPTIONS:
    -c, --category CATEGORY    Run tests for specific category only
                              Available: unit, integration, compatibility, error-handling, development
    -v, --verbose             Enable verbose output
    -r, --report              Generate detailed test report (text format)
    -j, --json                Generate test report in JSON format
    -s, --summary             Generate summary report from existing reports
    -l, --list               List available test categories
    -h, --help               Show this help message

EXAMPLES:
    $0                        # Run all test categories
    $0 --category unit        # Run only unit tests
    $0 --verbose --report     # Run all tests with verbose output and generate report
    $0 -c integration -v      # Run integration tests with verbose output
    $0 --report --json        # Generate both text and JSON reports
    $0 --summary              # Generate summary from existing reports

CATEGORIES:
    unit                     Unit tests for individual functions
    integration              Integration tests for complete workflows
    compatibility            Cross-platform and version compatibility tests
    error-handling           Error handling and recovery tests
    development              Development and debugging utilities

EOF
}

# Function to list available test categories
list_categories() {
    log_header "Available Test Categories"
    
    for category in $ALL_CATEGORIES; do
        local scripts="$(get_category_scripts "$category")"
        local script_count=$(echo "$scripts" | wc -w)
        
        echo -e "${CYAN}$category${NC} ($script_count scripts):"
        for script in $scripts; do
            local script_path="$PROJECT_ROOT/$script"
            if [ -f "$script_path" ] && [ -x "$script_path" ]; then
                echo -e "  ${GREEN}✓${NC} $script"
            else
                echo -e "  ${RED}✗${NC} $script (missing or not executable)"
            fi
        done
        echo
    done
}

# Function to validate test script exists and is executable
validate_test_script() {
    local script_path="$1"
    local full_path="$PROJECT_ROOT/$script_path"
    
    if [ ! -f "$full_path" ]; then
        log_error "Test script not found: $script_path"
        return 1
    fi
    
    if [ ! -x "$full_path" ]; then
        log_error "Test script not executable: $script_path"
        return 1
    fi
    
    return 0
}

# Function to execute a single test script
execute_test_script() {
    local script_path="$1"
    local category="$2"
    local full_path="$PROJECT_ROOT/$script_path"
    local script_name=$(basename "$script_path")
    
    log_verbose "Executing test script: $script_path"
    
    # Change to project root for consistent execution context
    cd "$PROJECT_ROOT"
    
    local start_time=$(date +%s)
    local exit_code=0
    local output=""
    local errors=""
    
    if [ "$VERBOSE" = true ]; then
        # Run with output visible
        bash "$full_path" || exit_code=$?
    else
        # Capture output and only show on failure
        output=$(bash "$full_path" 2>&1) || exit_code=$?
        
        if [ $exit_code -ne 0 ]; then
            echo -e "${RED}Output from failed test:${NC}"
            echo "$output"
            errors="$output"
        fi
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Determine test status
    local status
    if [ $exit_code -eq 0 ]; then
        status="$TEST_STATUS_PASS"
        log_success "$script_name completed successfully (${duration}s)"
        TOTAL_TESTS_PASSED=$((TOTAL_TESTS_PASSED + 1))
    else
        status="$TEST_STATUS_FAIL"
        log_error "$script_name failed with exit code $exit_code (${duration}s)"
        TOTAL_TESTS_FAILED=$((TOTAL_TESTS_FAILED + 1))
        FAILED_TESTS+=("$script_path")
    fi
    
    TOTAL_TESTS_RUN=$((TOTAL_TESTS_RUN + 1))
    
    # Record test result for reporting
    if [ "$GENERATE_REPORT" = true ] || [ "$GENERATE_JSON" = true ]; then
        record_test_result "$script_name" "$category" "$status" "$duration" "$script_path" "$exit_code" "$output" "$errors" "$start_time" "$end_time"
    fi
    
    return $exit_code
}

# Function to execute tests for a specific category
execute_category() {
    local category="$1"
    local scripts="$(get_category_scripts "$category")"
    
    if [ -z "$scripts" ]; then
        log_error "Unknown test category: $category"
        return 1
    fi
    
    log_header "Running $category tests"
    
    local category_start_time=$(date +%s)
    local category_passed=0
    local category_failed=0
    
    for script in $scripts; do
        if validate_test_script "$script"; then
            if execute_test_script "$script" "$category"; then
                category_passed=$((category_passed + 1))
            else
                category_failed=$((category_failed + 1))
            fi
        else
            category_failed=$((category_failed + 1))
            TOTAL_TESTS_RUN=$((TOTAL_TESTS_RUN + 1))
            TOTAL_TESTS_FAILED=$((TOTAL_TESTS_FAILED + 1))
            FAILED_TESTS+=("$script")
            
            # Record failed validation as error result
            if [ "$GENERATE_REPORT" = true ] || [ "$GENERATE_JSON" = true ]; then
                local script_name=$(basename "$script")
                record_test_result "$script_name" "$category" "$TEST_STATUS_ERROR" "0" "$script" "1" "" "Script validation failed" "0" "0"
            fi
        fi
    done
    
    local category_end_time=$(date +%s)
    local category_duration=$((category_end_time - category_start_time))
    
    TOTAL_CATEGORIES_RUN=$((TOTAL_CATEGORIES_RUN + 1))
    
    echo
    log_info "Category '$category' summary: $category_passed passed, $category_failed failed (${category_duration}s)"
    echo
    
    return $category_failed
}

# Function to generate final test report
generate_final_report() {
    local overall_result="PASSED"
    if [ $TOTAL_TESTS_FAILED -gt 0 ]; then
        overall_result="FAILED"
    fi
    
    log_header "Test Execution Summary"
    
    echo -e "${BOLD}Overall Result:${NC} $overall_result"
    echo -e "${BOLD}Categories Run:${NC} $TOTAL_CATEGORIES_RUN"
    echo -e "${BOLD}Total Tests:${NC} $TOTAL_TESTS_RUN"
    echo -e "${BOLD}Passed:${NC} ${GREEN}$TOTAL_TESTS_PASSED${NC}"
    echo -e "${BOLD}Failed:${NC} ${RED}$TOTAL_TESTS_FAILED${NC}"
    
    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        echo
        echo -e "${RED}${BOLD}Failed Tests:${NC}"
        for failed_test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $failed_test"
        done
    fi
    
    # Generate reports using the new reporting system
    if [ "$GENERATE_REPORT" = true ]; then
        echo
        log_info "Generating detailed text report..."
        generate_text_report "$REPORT_FILE" "TYPO3 Auto-Install Test Suite Report"
        log_info "Detailed report saved to: $REPORT_FILE"
    fi
    
    if [ "$GENERATE_JSON" = true ]; then
        echo
        log_info "Generating JSON report..."
        generate_json_report "$JSON_REPORT_FILE"
        log_info "JSON report saved to: $JSON_REPORT_FILE"
    fi
    
    if [ "$GENERATE_SUMMARY" = true ]; then
        echo
        log_info "Generating summary report from existing reports..."
        # Find recent report files (macOS compatible)
        local recent_reports=()
        if [ -d "$REPORTS_DIR" ]; then
            # Get the 10 most recent text reports
            local recent_files=$(find "$REPORTS_DIR" -name "test_run_report_*.txt" -type f | sort | tail -n 10)
            if [ -n "$recent_files" ]; then
                while IFS= read -r line; do
                    if [ -n "$line" ]; then
                        recent_reports+=("$line")
                    fi
                done <<< "$recent_files"
            fi
        fi
        
        if [ ${#recent_reports[@]} -gt 0 ]; then
            generate_summary_report "$SUMMARY_REPORT_FILE" "${recent_reports[@]}"
            log_info "Summary report saved to: $SUMMARY_REPORT_FILE"
        else
            log_warning "No existing reports found for summary generation"
        fi
    fi
}

# Function to initialize report file
initialize_report() {
    if [ "$GENERATE_REPORT" = true ]; then
        cat > "$REPORT_FILE" << EOF
TYPO3 Auto-Install Test Suite Report
Generated: $(date)
Command: $0 $*

=== Test Configuration ===
Project Root: $PROJECT_ROOT
Tests Directory: $TESTS_DIR
Reports Directory: $REPORTS_DIR
Verbose Mode: $VERBOSE
Category Filter: ${CATEGORY:-"all"}

=== Test Execution Log ===

EOF
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--category)
            CATEGORY="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -r|--report)
            GENERATE_REPORT=true
            shift
            ;;
        -j|--json)
            GENERATE_JSON=true
            shift
            ;;
        -s|--summary)
            GENERATE_SUMMARY=true
            shift
            ;;
        -l|--list)
            LIST_CATEGORIES=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Handle list categories option
if [ "$LIST_CATEGORIES" = true ]; then
    list_categories
    exit 0
fi

# Validate category if specified
if [ -n "$CATEGORY" ] && [ -z "$(get_category_scripts "$CATEGORY")" ]; then
    log_error "Invalid category: $CATEGORY"
    echo "Available categories: $ALL_CATEGORIES"
    exit 1
fi

# Initialize test reporting system if any reports are requested
if [ "$GENERATE_REPORT" = true ] || [ "$GENERATE_JSON" = true ] || [ "$GENERATE_SUMMARY" = true ]; then
    init_test_reporting "$REPORTS_DIR" "$TIMESTAMP"
fi

# Initialize legacy report if requested (for backward compatibility)
initialize_report

# Main execution
log_header "TYPO3 Auto-Install Test Suite"
log_info "Starting test execution at $(date)"
log_verbose "Project root: $PROJECT_ROOT"
log_verbose "Tests directory: $TESTS_DIR"

if [ -n "$CATEGORY" ]; then
    # Run specific category
    log_info "Running tests for category: $CATEGORY"
    execute_category "$CATEGORY"
    exit_code=$?
else
    # Run all categories
    log_info "Running all test categories"
    exit_code=0
    
    for category in $ALL_CATEGORIES; do
        if [ -n "$(get_category_scripts "$category")" ]; then
            execute_category "$category" || exit_code=1
        fi
    done
fi

# Generate final summary
generate_final_report

# Exit with appropriate code
if [ $TOTAL_TESTS_FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi