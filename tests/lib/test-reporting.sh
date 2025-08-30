#!/bin/bash

# Test Result Reporting Library
# Provides standardized test result format and reporting functions
# Requirements: 5.3, 5.4

# Test result status constants
readonly TEST_STATUS_PASS="PASS"
readonly TEST_STATUS_FAIL="FAIL"
readonly TEST_STATUS_SKIP="SKIP"
readonly TEST_STATUS_ERROR="ERROR"

# Report format constants
readonly REPORT_FORMAT_TEXT="text"
readonly REPORT_FORMAT_JSON="json"
readonly REPORT_FORMAT_HTML="html"

# Helper functions for metadata management (bash 3.2 compatible)
set_metadata() {
    local key="$1"
    local value="$2"
    
    # Check if key already exists
    local found=false
    local index=0
    for existing_key in "${TEST_METADATA_KEYS[@]}"; do
        if [ "$existing_key" = "$key" ]; then
            TEST_METADATA_VALUES[$index]="$value"
            found=true
            break
        fi
        index=$((index + 1))
    done
    
    # Add new key-value pair if not found
    if [ "$found" = false ]; then
        TEST_METADATA_KEYS+=("$key")
        TEST_METADATA_VALUES+=("$value")
    fi
}

get_metadata() {
    local key="$1"
    local index=0
    
    for existing_key in "${TEST_METADATA_KEYS[@]}"; do
        if [ "$existing_key" = "$key" ]; then
            echo "${TEST_METADATA_VALUES[$index]}"
            return 0
        fi
        index=$((index + 1))
    done
    
    return 1
}

# Global test result storage (bash 3.2 compatible)
TEST_RESULTS=()
TEST_METADATA_KEYS=()
TEST_METADATA_VALUES=()

# Test result structure (JSON-like format for bash compatibility)
# {
#   "test_name": "string",
#   "category": "string", 
#   "status": "PASS|FAIL|SKIP|ERROR",
#   "duration": "number",
#   "start_time": "timestamp",
#   "end_time": "timestamp", 
#   "output": "string",
#   "errors": ["string"],
#   "script_path": "string",
#   "exit_code": "number"
# }

# Initialize test result tracking
init_test_reporting() {
    local report_dir="$1"
    local session_id="${2:-$(date +%Y%m%d_%H%M%S)}"
    
    # Ensure reports directory exists
    mkdir -p "$report_dir"
    
    # Set global reporting variables
    TEST_REPORT_DIR="$report_dir"
    TEST_SESSION_ID="$session_id"
    TEST_START_TIME=$(date +%s)
    TEST_RESULTS=()
    
    # Initialize metadata (bash 3.2 compatible)
    set_metadata "session_id" "$session_id"
    set_metadata "start_time" "$TEST_START_TIME"
    set_metadata "hostname" "$(hostname)"
    set_metadata "os" "$(uname -s)"
    set_metadata "arch" "$(uname -m)"
    set_metadata "shell" "$SHELL"
    set_metadata "user" "$(whoami)"
    set_metadata "pwd" "$(pwd)"
}

# Record a test result
record_test_result() {
    local test_name="$1"
    local category="$2"
    local status="$3"
    local duration="$4"
    local script_path="$5"
    local exit_code="$6"
    local output="$7"
    local errors="$8"
    
    local start_time="$9"
    local end_time="${10}"
    
    # Validate required parameters
    if [ -z "$test_name" ] || [ -z "$category" ] || [ -z "$status" ]; then
        echo "ERROR: record_test_result requires test_name, category, and status" >&2
        return 1
    fi
    
    # Validate status
    case "$status" in
        "$TEST_STATUS_PASS"|"$TEST_STATUS_FAIL"|"$TEST_STATUS_SKIP"|"$TEST_STATUS_ERROR")
            ;;
        *)
            echo "ERROR: Invalid test status: $status" >&2
            return 1
            ;;
    esac
    
    # Create test result entry (using array index as ID)
    local result_id=${#TEST_RESULTS[@]}
    
    # Store result data (bash 3.2 compatible format)
    TEST_RESULTS[$result_id]="$test_name|$category|$status|$duration|$script_path|$exit_code|$start_time|$end_time"
    
    # Store output and errors separately (handle multiline content)
    if [ -n "$output" ]; then
        set_metadata "result_${result_id}_output" "$output"
    fi
    if [ -n "$errors" ]; then
        set_metadata "result_${result_id}_errors" "$errors"
    fi
    
    return 0
}

# Get test result by ID
get_test_result() {
    local result_id="$1"
    
    if [ -z "$result_id" ] || [ "$result_id" -ge ${#TEST_RESULTS[@]} ]; then
        echo "ERROR: Invalid result ID: $result_id" >&2
        return 1
    fi
    
    echo "${TEST_RESULTS[$result_id]}"
}

# Parse test result data
parse_test_result() {
    local result_data="$1"
    local field="$2"
    
    if [ -z "$result_data" ]; then
        return 1
    fi
    
    # Split result data by pipe separator
    local test_name=$(echo "$result_data" | cut -d'|' -f1)
    local category=$(echo "$result_data" | cut -d'|' -f2)
    local status=$(echo "$result_data" | cut -d'|' -f3)
    local duration=$(echo "$result_data" | cut -d'|' -f4)
    local script_path=$(echo "$result_data" | cut -d'|' -f5)
    local exit_code=$(echo "$result_data" | cut -d'|' -f6)
    local start_time=$(echo "$result_data" | cut -d'|' -f7)
    local end_time=$(echo "$result_data" | cut -d'|' -f8)
    
    case "$field" in
        "test_name") echo "$test_name" ;;
        "category") echo "$category" ;;
        "status") echo "$status" ;;
        "duration") echo "$duration" ;;
        "script_path") echo "$script_path" ;;
        "exit_code") echo "$exit_code" ;;
        "start_time") echo "$start_time" ;;
        "end_time") echo "$end_time" ;;
        *) echo "ERROR: Unknown field: $field" >&2; return 1 ;;
    esac
}

# Calculate test statistics
calculate_test_statistics() {
    local total_tests=${#TEST_RESULTS[@]}
    local passed_tests=0
    local failed_tests=0
    local skipped_tests=0
    local error_tests=0
    local total_duration=0
    
    # Count results by status
    for i in $(seq 0 $((total_tests - 1))); do
        local result_data="${TEST_RESULTS[$i]}"
        local status=$(parse_test_result "$result_data" "status")
        local duration=$(parse_test_result "$result_data" "duration")
        
        case "$status" in
            "$TEST_STATUS_PASS") passed_tests=$((passed_tests + 1)) ;;
            "$TEST_STATUS_FAIL") failed_tests=$((failed_tests + 1)) ;;
            "$TEST_STATUS_SKIP") skipped_tests=$((skipped_tests + 1)) ;;
            "$TEST_STATUS_ERROR") error_tests=$((error_tests + 1)) ;;
        esac
        
        if [ -n "$duration" ] && [ "$duration" -gt 0 ]; then
            total_duration=$((total_duration + duration))
        fi
    done
    
    # Calculate success rate
    local success_rate=0
    if [ $total_tests -gt 0 ]; then
        success_rate=$((passed_tests * 100 / total_tests))
    fi
    
    # Return statistics as pipe-separated values
    echo "$total_tests|$passed_tests|$failed_tests|$skipped_tests|$error_tests|$total_duration|$success_rate"
}

# Generate text format report
generate_text_report() {
    local output_file="$1"
    local title="${2:-Test Execution Report}"
    
    local stats=$(calculate_test_statistics)
    local total_tests=$(echo "$stats" | cut -d'|' -f1)
    local passed_tests=$(echo "$stats" | cut -d'|' -f2)
    local failed_tests=$(echo "$stats" | cut -d'|' -f3)
    local skipped_tests=$(echo "$stats" | cut -d'|' -f4)
    local error_tests=$(echo "$stats" | cut -d'|' -f5)
    local total_duration=$(echo "$stats" | cut -d'|' -f6)
    local success_rate=$(echo "$stats" | cut -d'|' -f7)
    
    # Generate report header
    cat > "$output_file" << EOF
$title
$(printf '=%.0s' $(seq 1 ${#title}))

Report Generated: $(date)
Session ID: $(get_metadata "session_id")
Total Duration: ${total_duration}s
Test Environment: $(get_metadata "os") $(get_metadata "arch")
Hostname: $(get_metadata "hostname")
User: $(get_metadata "user")
Working Directory: $(get_metadata "pwd")

OVERALL SUMMARY
===============
Total Tests: $total_tests
Passed: $passed_tests
Failed: $failed_tests
Skipped: $skipped_tests
Errors: $error_tests
Success Rate: ${success_rate}%

EOF

    # Add detailed results if there are any tests
    if [ $total_tests -gt 0 ]; then
        echo "DETAILED TEST RESULTS" >> "$output_file"
        echo "=====================" >> "$output_file"
        echo >> "$output_file"
        
        # Group results by category
        local categories=()
        for i in $(seq 0 $((total_tests - 1))); do
            local result_data="${TEST_RESULTS[$i]}"
            local category=$(parse_test_result "$result_data" "category")
            
            # Add category to list if not already present
            local found=false
            for existing_cat in "${categories[@]}"; do
                if [ "$existing_cat" = "$category" ]; then
                    found=true
                    break
                fi
            done
            if [ "$found" = false ]; then
                categories+=("$category")
            fi
        done
        
        # Generate results for each category
        for category in "${categories[@]}"; do
            echo "Category: $category" >> "$output_file"
            echo "$(printf -- '-%.0s' $(seq 1 $((${#category} + 10))))" >> "$output_file"
            
            for i in $(seq 0 $((total_tests - 1))); do
                local result_data="${TEST_RESULTS[$i]}"
                local test_category=$(parse_test_result "$result_data" "category")
                
                if [ "$test_category" = "$category" ]; then
                    local test_name=$(parse_test_result "$result_data" "test_name")
                    local status=$(parse_test_result "$result_data" "status")
                    local duration=$(parse_test_result "$result_data" "duration")
                    local script_path=$(parse_test_result "$result_data" "script_path")
                    local exit_code=$(parse_test_result "$result_data" "exit_code")
                    
                    # Format status with color indicators (for text)
                    local status_indicator
                    case "$status" in
                        "$TEST_STATUS_PASS") status_indicator="✓ PASS" ;;
                        "$TEST_STATUS_FAIL") status_indicator="✗ FAIL" ;;
                        "$TEST_STATUS_SKIP") status_indicator="- SKIP" ;;
                        "$TEST_STATUS_ERROR") status_indicator="! ERROR" ;;
                    esac
                    
                    echo "  $status_indicator $test_name (${duration}s)" >> "$output_file"
                    echo "    Script: $script_path" >> "$output_file"
                    if [ "$exit_code" != "0" ]; then
                        echo "    Exit Code: $exit_code" >> "$output_file"
                    fi
                    
                    # Add output if available
                    local output="$(get_metadata "result_${i}_output")"
                    if [ -n "$output" ]; then
                        echo "    Output:" >> "$output_file"
                        echo "$output" | sed 's/^/      /' >> "$output_file"
                    fi
                    
                    # Add errors if available
                    local errors="$(get_metadata "result_${i}_errors")"
                    if [ -n "$errors" ]; then
                        echo "    Errors:" >> "$output_file"
                        echo "$errors" | sed 's/^/      /' >> "$output_file"
                    fi
                    
                    echo >> "$output_file"
                fi
            done
            echo >> "$output_file"
        done
    fi
    
    # Add footer
    echo "Report generated by TYPO3 Auto-Install Test Suite" >> "$output_file"
    echo "End of report" >> "$output_file"
}

# Generate JSON format report
generate_json_report() {
    local output_file="$1"
    
    local stats=$(calculate_test_statistics)
    local total_tests=$(echo "$stats" | cut -d'|' -f1)
    local passed_tests=$(echo "$stats" | cut -d'|' -f2)
    local failed_tests=$(echo "$stats" | cut -d'|' -f3)
    local skipped_tests=$(echo "$stats" | cut -d'|' -f4)
    local error_tests=$(echo "$stats" | cut -d'|' -f5)
    local total_duration=$(echo "$stats" | cut -d'|' -f6)
    local success_rate=$(echo "$stats" | cut -d'|' -f7)
    
    # Start JSON structure
    cat > "$output_file" << EOF
{
  "metadata": {
    "session_id": "$(get_metadata "session_id")",
    "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "start_time": $(get_metadata "start_time"),
    "end_time": $(date +%s),
    "environment": {
      "hostname": "$(get_metadata "hostname")",
      "os": "$(get_metadata "os")",
      "arch": "$(get_metadata "arch")",
      "shell": "$(get_metadata "shell")",
      "user": "$(get_metadata "user")",
      "working_directory": "$(get_metadata "pwd")"
    }
  },
  "summary": {
    "total_tests": $total_tests,
    "passed": $passed_tests,
    "failed": $failed_tests,
    "skipped": $skipped_tests,
    "errors": $error_tests,
    "total_duration": $total_duration,
    "success_rate": $success_rate
  },
  "results": [
EOF

    # Add test results
    for i in $(seq 0 $((total_tests - 1))); do
        local result_data="${TEST_RESULTS[$i]}"
        local test_name=$(parse_test_result "$result_data" "test_name")
        local category=$(parse_test_result "$result_data" "category")
        local status=$(parse_test_result "$result_data" "status")
        local duration=$(parse_test_result "$result_data" "duration")
        local script_path=$(parse_test_result "$result_data" "script_path")
        local exit_code=$(parse_test_result "$result_data" "exit_code")
        local start_time=$(parse_test_result "$result_data" "start_time")
        local end_time=$(parse_test_result "$result_data" "end_time")
        
        # Escape JSON strings
        test_name=$(echo "$test_name" | sed 's/"/\\"/g')
        category=$(echo "$category" | sed 's/"/\\"/g')
        script_path=$(echo "$script_path" | sed 's/"/\\"/g')
        
        # Add comma if not first result
        if [ $i -gt 0 ]; then
            echo "," >> "$output_file"
        fi
        
        cat >> "$output_file" << EOF
    {
      "test_name": "$test_name",
      "category": "$category",
      "status": "$status",
      "duration": $duration,
      "script_path": "$script_path",
      "exit_code": $exit_code,
      "start_time": $start_time,
      "end_time": $end_time
EOF

        # Add output if available
        local output="$(get_metadata "result_${i}_output")"
        if [ -n "$output" ]; then
            output=$(echo "$output" | sed 's/"/\\"/g' | tr '\n' ' ')
            echo ",      \"output\": \"$output\"" >> "$output_file"
        fi
        
        # Add errors if available
        local errors="$(get_metadata "result_${i}_errors")"
        if [ -n "$errors" ]; then
            errors=$(echo "$errors" | sed 's/"/\\"/g' | tr '\n' ' ')
            echo ",      \"errors\": \"$errors\"" >> "$output_file"
        fi
        
        echo "    }" >> "$output_file"
    done
    
    # Close JSON structure
    cat >> "$output_file" << EOF
  ]
}
EOF
}

# Generate summary report for multiple test runs
generate_summary_report() {
    local output_file="$1"
    local report_files=("${@:2}")
    
    if [ ${#report_files[@]} -eq 0 ]; then
        echo "ERROR: No report files specified for summary" >&2
        return 1
    fi
    
    cat > "$output_file" << EOF
TYPO3 Auto-Install Test Suite - Summary Report
==============================================

Generated: $(date)
Report Files Analyzed: ${#report_files[@]}

EOF

    # Analyze each report file
    local total_runs=0
    local total_tests_all=0
    local total_passed_all=0
    local total_failed_all=0
    
    for report_file in "${report_files[@]}"; do
        if [ -f "$report_file" ]; then
            echo "Report: $(basename "$report_file")" >> "$output_file"
            echo "----------------------------------------" >> "$output_file"
            
            # Extract summary information from text reports
            if grep -q "Total Tests:" "$report_file"; then
                local total_tests=$(grep "Total Tests:" "$report_file" | awk '{print $3}')
                local passed=$(grep "Passed:" "$report_file" | awk '{print $2}')
                local failed=$(grep "Failed:" "$report_file" | awk '{print $2}')
                local success_rate=$(grep "Success Rate:" "$report_file" | awk '{print $3}')
                
                echo "  Total Tests: $total_tests" >> "$output_file"
                echo "  Passed: $passed" >> "$output_file"
                echo "  Failed: $failed" >> "$output_file"
                echo "  Success Rate: $success_rate" >> "$output_file"
                
                total_runs=$((total_runs + 1))
                total_tests_all=$((total_tests_all + total_tests))
                total_passed_all=$((total_passed_all + passed))
                total_failed_all=$((total_failed_all + failed))
            else
                echo "  Status: Unable to parse report" >> "$output_file"
            fi
            echo >> "$output_file"
        fi
    done
    
    # Add overall summary
    if [ $total_runs -gt 0 ]; then
        local overall_success_rate=0
        if [ $total_tests_all -gt 0 ]; then
            overall_success_rate=$((total_passed_all * 100 / total_tests_all))
        fi
        
        cat >> "$output_file" << EOF
OVERALL SUMMARY ACROSS ALL RUNS
===============================
Total Test Runs: $total_runs
Total Tests Executed: $total_tests_all
Total Passed: $total_passed_all
Total Failed: $total_failed_all
Overall Success Rate: ${overall_success_rate}%

EOF
    fi
    
    echo "Summary report generated: $output_file"
}

# Export functions for use in other scripts
export -f init_test_reporting
export -f record_test_result
export -f get_test_result
export -f parse_test_result
export -f calculate_test_statistics
export -f generate_text_report
export -f generate_json_report
export -f generate_summary_report