#!/bin/bash

# Test Report Generation Utility
# Generates various types of reports from test execution data
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

# Configuration variables
REPORT_TYPE="summary"
OUTPUT_FILE=""
INPUT_FILES=()
VERBOSE=false
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${YELLOW}[VERBOSE]${NC} $1"
    fi
}

# Function to display usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Generate various types of test reports from existing test data.

OPTIONS:
    -t, --type TYPE          Type of report to generate (summary, analysis, trends)
    -o, --output FILE        Output file path (default: auto-generated)
    -i, --input FILE         Input report file (can be specified multiple times)
    -v, --verbose            Enable verbose output
    -h, --help               Show this help message

REPORT TYPES:
    summary                  Generate summary from multiple test reports
    analysis                 Generate detailed analysis of test patterns
    trends                   Generate trend analysis from historical data

EXAMPLES:
    $0 --type summary                           # Generate summary from recent reports
    $0 --type analysis --input report1.txt     # Analyze specific report
    $0 --type trends --verbose                  # Generate trend analysis with verbose output
    $0 -t summary -o custom_summary.txt        # Generate summary with custom output file

EOF
}

# Function to find recent report files (macOS/bash 3.2 compatible)
find_recent_reports() {
    local max_reports="${1:-10}"
    
    if [ -d "$REPORTS_DIR" ]; then
        log_verbose "Searching for recent reports in: $REPORTS_DIR"
        
        # Find text reports first (macOS compatible)
        find "$REPORTS_DIR" -name "test_run_report_*.txt" -type f | sort | tail -n "$max_reports"
        
        # If no text reports found, look for any report files
        local report_count=$(find "$REPORTS_DIR" -name "test_run_report_*.txt" -type f | wc -l)
        if [ "$report_count" -eq 0 ]; then
            find "$REPORTS_DIR" -name "*report*.txt" -type f | sort | tail -n "$max_reports"
        fi
    fi
}

# Function to generate summary report
generate_summary_report_wrapper() {
    local output_file="$1"
    shift
    local input_files=("$@")
    
    if [ ${#input_files[@]} -eq 0 ]; then
        log_info "No input files specified, searching for recent reports..."
        
        # Read recent reports into array (bash 3.2 compatible)
        local recent_reports_list=$(find_recent_reports 10)
        local recent_reports=()
        
        if [ -n "$recent_reports_list" ]; then
            while IFS= read -r line; do
                if [ -n "$line" ]; then
                    recent_reports+=("$line")
                fi
            done <<< "$recent_reports_list"
        fi
        
        if [ ${#recent_reports[@]} -eq 0 ]; then
            log_error "No report files found in $REPORTS_DIR"
            return 1
        fi
        
        input_files=("${recent_reports[@]}")
        log_info "Found ${#input_files[@]} recent reports"
    fi
    
    log_info "Generating summary report from ${#input_files[@]} input files..."
    log_verbose "Output file: $output_file"
    
    for file in "${input_files[@]}"; do
        log_verbose "Input file: $file"
    done
    
    generate_summary_report "$output_file" "${input_files[@]}"
    
    if [ $? -eq 0 ]; then
        log_success "Summary report generated: $output_file"
    else
        log_error "Failed to generate summary report"
        return 1
    fi
}

# Function to generate analysis report
generate_analysis_report() {
    local output_file="$1"
    shift
    local input_files=("$@")
    
    if [ ${#input_files[@]} -eq 0 ]; then
        log_error "Analysis report requires at least one input file"
        return 1
    fi
    
    log_info "Generating analysis report..."
    
    cat > "$output_file" << EOF
TYPO3 Auto-Install Test Suite - Analysis Report
==============================================

Generated: $(date)
Input Files: ${#input_files[@]}

EOF

    # Analyze each input file
    local total_files=0
    local files_with_failures=0
    local most_common_failures=()
    
    for input_file in "${input_files[@]}"; do
        if [ ! -f "$input_file" ]; then
            log_warning "Input file not found: $input_file"
            continue
        fi
        
        total_files=$((total_files + 1))
        
        echo "Analysis of: $(basename "$input_file")" >> "$output_file"
        echo "----------------------------------------" >> "$output_file"
        
        # Extract key metrics
        if grep -q "Total Tests:" "$input_file"; then
            local total_tests=$(grep "Total Tests:" "$input_file" | awk '{print $3}')
            local failed_tests=$(grep "Failed:" "$input_file" | awk '{print $2}')
            local success_rate=$(grep "Success Rate:" "$input_file" | awk '{print $3}')
            
            echo "  Total Tests: $total_tests" >> "$output_file"
            echo "  Failed Tests: $failed_tests" >> "$output_file"
            echo "  Success Rate: $success_rate" >> "$output_file"
            
            if [ "$failed_tests" -gt 0 ]; then
                files_with_failures=$((files_with_failures + 1))
                
                # Extract failed test names
                echo "  Failed Test Details:" >> "$output_file"
                if grep -A 20 "Failed Tests:" "$input_file" | grep -E "^\s*✗" > /dev/null; then
                    grep -A 20 "Failed Tests:" "$input_file" | grep -E "^\s*✗" | sed 's/^/    /' >> "$output_file"
                fi
            fi
        else
            echo "  Status: Unable to parse test metrics" >> "$output_file"
        fi
        
        echo >> "$output_file"
    done
    
    # Add overall analysis
    cat >> "$output_file" << EOF
OVERALL ANALYSIS
===============
Total Report Files Analyzed: $total_files
Files with Test Failures: $files_with_failures
Failure Rate: $((files_with_failures * 100 / total_files))%

RECOMMENDATIONS
==============
EOF

    if [ $files_with_failures -eq 0 ]; then
        echo "✓ All analyzed test runs were successful" >> "$output_file"
        echo "✓ Test suite appears to be stable" >> "$output_file"
    elif [ $((files_with_failures * 100 / total_files)) -lt 25 ]; then
        echo "⚠ Low failure rate detected - investigate occasional failures" >> "$output_file"
        echo "⚠ Consider adding more robust error handling" >> "$output_file"
    else
        echo "⚠ High failure rate detected - immediate attention required" >> "$output_file"
        echo "⚠ Review test environment and dependencies" >> "$output_file"
        echo "⚠ Consider stabilizing failing tests before adding new ones" >> "$output_file"
    fi
    
    echo >> "$output_file"
    echo "Analysis completed: $(date)" >> "$output_file"
    
    log_success "Analysis report generated: $output_file"
}

# Function to generate trends report
generate_trends_report() {
    local output_file="$1"
    shift
    local input_files=("$@")
    
    if [ ${#input_files[@]} -eq 0 ]; then
        log_info "No input files specified, searching for recent reports..."
        
        # Read recent reports into array (bash 3.2 compatible)
        local recent_reports_list=$(find_recent_reports 20)
        local recent_reports=()
        
        if [ -n "$recent_reports_list" ]; then
            while IFS= read -r line; do
                if [ -n "$line" ]; then
                    recent_reports+=("$line")
                fi
            done <<< "$recent_reports_list"
        fi
        
        if [ ${#recent_reports[@]} -lt 3 ]; then
            log_error "Trends analysis requires at least 3 report files"
            return 1
        fi
        
        input_files=("${recent_reports[@]}")
        log_info "Found ${#input_files[@]} reports for trend analysis"
    fi
    
    log_info "Generating trends report..."
    
    cat > "$output_file" << EOF
TYPO3 Auto-Install Test Suite - Trends Report
=============================================

Generated: $(date)
Report Files Analyzed: ${#input_files[@]}

EOF

    # Extract trend data
    local dates=()
    local success_rates=()
    local total_tests=()
    
    for input_file in "${input_files[@]}"; do
        if [ ! -f "$input_file" ]; then
            continue
        fi
        
        # Extract date from filename or file content
        local file_date=""
        if [[ "$(basename "$input_file")" =~ _([0-9]{8}_[0-9]{6}) ]]; then
            file_date="${BASH_REMATCH[1]}"
        else
            # Try to extract from file content
            file_date=$(grep "Generated:" "$input_file" | head -1 | awk '{print $2, $3}' | tr -d ',')
        fi
        
        # Extract metrics
        if grep -q "Success Rate:" "$input_file"; then
            local success_rate=$(grep "Success Rate:" "$input_file" | awk '{print $3}' | tr -d '%')
            local total_test_count=$(grep "Total Tests:" "$input_file" | awk '{print $3}')
            
            dates+=("$file_date")
            success_rates+=("$success_rate")
            total_tests+=("$total_test_count")
        fi
    done
    
    # Generate trends analysis
    if [ ${#success_rates[@]} -gt 0 ]; then
        echo "TREND DATA" >> "$output_file"
        echo "==========" >> "$output_file"
        echo >> "$output_file"
        
        for i in $(seq 0 $((${#dates[@]} - 1))); do
            echo "Date: ${dates[$i]:-Unknown} | Tests: ${total_tests[$i]:-0} | Success Rate: ${success_rates[$i]:-0}%" >> "$output_file"
        done
        
        echo >> "$output_file"
        
        # Calculate trend statistics
        local min_success_rate=100
        local max_success_rate=0
        local total_success_rate=0
        local valid_rates=0
        
        for rate in "${success_rates[@]}"; do
            if [ -n "$rate" ] && [ "$rate" -ge 0 ] && [ "$rate" -le 100 ]; then
                if [ "$rate" -lt "$min_success_rate" ]; then
                    min_success_rate="$rate"
                fi
                if [ "$rate" -gt "$max_success_rate" ]; then
                    max_success_rate="$rate"
                fi
                total_success_rate=$((total_success_rate + rate))
                valid_rates=$((valid_rates + 1))
            fi
        done
        
        if [ $valid_rates -gt 0 ]; then
            local avg_success_rate=$((total_success_rate / valid_rates))
            
            echo "TREND ANALYSIS" >> "$output_file"
            echo "==============" >> "$output_file"
            echo "Minimum Success Rate: ${min_success_rate}%" >> "$output_file"
            echo "Maximum Success Rate: ${max_success_rate}%" >> "$output_file"
            echo "Average Success Rate: ${avg_success_rate}%" >> "$output_file"
            echo "Success Rate Range: $((max_success_rate - min_success_rate))%" >> "$output_file"
            echo >> "$output_file"
            
            # Trend assessment
            echo "TREND ASSESSMENT" >> "$output_file"
            echo "================" >> "$output_file"
            
            if [ $avg_success_rate -ge 90 ]; then
                echo "✓ Excellent test stability (>90% average success rate)" >> "$output_file"
            elif [ $avg_success_rate -ge 75 ]; then
                echo "⚠ Good test stability (75-90% average success rate)" >> "$output_file"
            else
                echo "⚠ Poor test stability (<75% average success rate)" >> "$output_file"
            fi
            
            local range=$((max_success_rate - min_success_rate))
            if [ $range -le 10 ]; then
                echo "✓ Consistent test results (≤10% variation)" >> "$output_file"
            elif [ $range -le 25 ]; then
                echo "⚠ Moderate test variation (10-25% variation)" >> "$output_file"
            else
                echo "⚠ High test variation (>25% variation)" >> "$output_file"
            fi
        fi
    else
        echo "No valid trend data found in input files" >> "$output_file"
    fi
    
    echo >> "$output_file"
    echo "Trends analysis completed: $(date)" >> "$output_file"
    
    log_success "Trends report generated: $output_file"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            REPORT_TYPE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -i|--input)
            INPUT_FILES+=("$2")
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
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

# Validate report type
case "$REPORT_TYPE" in
    summary|analysis|trends)
        ;;
    *)
        log_error "Invalid report type: $REPORT_TYPE"
        echo "Valid types: summary, analysis, trends"
        exit 1
        ;;
esac

# Set default output file if not specified
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="$REPORTS_DIR/${REPORT_TYPE}_report_$TIMESTAMP.txt"
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

log_info "Generating $REPORT_TYPE report..."
log_verbose "Output file: $OUTPUT_FILE"
log_verbose "Input files: ${#INPUT_FILES[@]}"

# Generate the requested report
case "$REPORT_TYPE" in
    summary)
        generate_summary_report_wrapper "$OUTPUT_FILE" "${INPUT_FILES[@]}"
        ;;
    analysis)
        generate_analysis_report "$OUTPUT_FILE" "${INPUT_FILES[@]}"
        ;;
    trends)
        generate_trends_report "$OUTPUT_FILE" "${INPUT_FILES[@]}"
        ;;
esac

exit_code=$?

if [ $exit_code -eq 0 ]; then
    log_success "Report generation completed successfully"
    log_info "Report saved to: $OUTPUT_FILE"
else
    log_error "Report generation failed"
fi

exit $exit_code